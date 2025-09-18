/**
 * \file            lwmem.c
 * \brief           Lightweight dynamic memory manager
 */

/*
 * Copyright (c) 2024 Tilen MAJERLE
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Software,
 * and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
 * AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 *
 * This file is part of LwMEM - Lightweight dynamic memory manager library.
 *
 * Author:          Tilen MAJERLE <tilen@majerle.eu>
 * Version:         v2.2.3
 */
#include "lwmem/lwmem.h"
#include <limits.h>
#include <stdint.h>
#include <string.h>

#if LWMEM_CFG_OS
#include "system/lwmem_sys.h"
#endif /* LWMEM_CFG_OS */

#if LWMEM_CFG_OS
#define LWMEM_PROTECT(lwobj)   lwmem_sys_mutex_wait(&((lwobj)->mutex))
#define LWMEM_UNPROTECT(lwobj) lwmem_sys_mutex_release(&((lwobj)->mutex))
#else /* LWMEM_CFG_OS */
#define LWMEM_PROTECT(lwobj)
#define LWMEM_UNPROTECT(lwobj)
#endif /* !LWMEM_CFG_OS */

/* Statistics part */
#if LWMEM_CFG_ENABLE_STATS
#define LWMEM_INC_STATS(field) (++(field))
#define LWMEM_UPDATE_MIN_FREE(lwobj)                                                                                   \
    do {                                                                                                               \
        if ((lwobj)->mem_available_bytes < (lwobj)->stats.minimum_ever_mem_available_bytes) {                          \
            (lwobj)->stats.minimum_ever_mem_available_bytes = (lwobj)->mem_available_bytes;                            \
        }                                                                                                              \
    } while (0)
#else
#define LWMEM_INC_STATS(field)
#define LWMEM_UPDATE_MIN_FREE(lwobj)
#endif /* LWMEM_CFG_ENABLE_STATS */

/* Verify alignment */
#if (LWMEM_CFG_ALIGN_NUM & (LWMEM_CFG_ALIGN_NUM - 1) > 0)
#error "LWMEM_ALIGN_BITS must be power of 2"
#endif

/**
 * \brief           LwMEM default structure used by application
 */
static lwmem_t lwmem_default;

/**
 * \brief           Get LwMEM instance based on user input
 * \param[in]       in_lwobj: LwMEM instance. Set to `NULL` for default instance
 */
#define LWMEM_GET_LWOBJ(in_lwobj) ((in_lwobj) != NULL ? (in_lwobj) : (&lwmem_default))

/**
 * \brief           Transform alignment number (power of `2`) to bits
 */
#define LWMEM_ALIGN_BITS          ((size_t)(((size_t)LWMEM_CFG_ALIGN_NUM) - 1))

/**
 * \brief           Aligns input value to next alignment bits
 *
 * As an example, when \ref LWMEM_CFG_ALIGN_NUM is set to `4`:
 *
 *  - Input: `0`; Output: `0`
 *  - Input: `1`; Output: `4`
 *  - Input: `2`; Output: `4`
 *  - Input: `3`; Output: `4`
 *  - Input: `4`; Output: `4`
 *  - Input: `5`; Output: `8`
 *  - Input: `6`; Output: `8`
 *  - Input: `7`; Output: `8`
 *  - Input: `8`; Output: `8`
 */
#define LWMEM_ALIGN(x)            (((x) + (LWMEM_ALIGN_BITS)) & ~(LWMEM_ALIGN_BITS))

/**
 * \brief           Cast input pointer to byte
 * \param[in]       p: Input pointer to cast to byte pointer
 */
#define LWMEM_TO_BYTE_PTR(p)      ((uint8_t*)(p))

#if LWMEM_CFG_FULL

/**
 * \brief           Size of metadata header for block information
 */
#define LWMEM_BLOCK_META_SIZE  LWMEM_ALIGN(sizeof(lwmem_block_t))

/**
 * \brief           Bit indicating memory block is allocated
 */
#define LWMEM_ALLOC_BIT        ((size_t)((size_t)1 << (sizeof(size_t) * CHAR_BIT - 1)))

/**
 * \brief           Mark written in `next` field when block is allocated
 */
#define LWMEM_BLOCK_ALLOC_MARK (0xDEADBEEF)

/**
 * \brief           Check if input block is properly allocated and valid
 * \param[in]       block: Block to check if properly set as allocated
 */
#define LWMEM_BLOCK_IS_ALLOC(block)                                                                                    \
    ((block) != NULL && ((block)->size & LWMEM_ALLOC_BIT)                                                              \
     && (block)->next == (void*)(LWMEM_TO_BYTE_PTR(0) + LWMEM_BLOCK_ALLOC_MARK))

/**
 * \brief           Get block handle from application pointer
 * \param[in]       ptr: Input pointer to get block from
 */
#define LWMEM_GET_BLOCK_FROM_PTR(ptr) (void*)((ptr) != NULL ? ((LWMEM_TO_BYTE_PTR(ptr)) - LWMEM_BLOCK_META_SIZE) : NULL)

/**
 * \brief           Get block handle from application pointer
 * \param[in]       block: Input pointer to get block from
 */
#define LWMEM_GET_PTR_FROM_BLOCK(block)                                                                                \
    (void*)((block) != NULL ? ((LWMEM_TO_BYTE_PTR(block)) + LWMEM_BLOCK_META_SIZE) : NULL)

/**
 * \brief           Minimum amount of memory required to make new empty block
 *
 * Default size is size of meta block
 */
#define LWMEM_BLOCK_MIN_SIZE (LWMEM_BLOCK_META_SIZE)

/**
 * \brief           Gets block before input block (marked as prev) and its previous free block
 * \param[in]       in_lwobj: LwMEM instance. Set to `NULL` to use default instance
 * \param[in]       in_b: Input block to find previous and its previous
 * \param[in]       in_pp: Previous previous of input block. Finding will be stored here
 * \param[in]       in_p: Previous of input block. Finding will be stored here
 */
static void
prv_get_prev_curr_of_block(lwmem_t* in_lwobj, const lwmem_block_t* in_b, lwmem_block_t** in_pp, lwmem_block_t** in_p) {
    for (*in_pp = NULL, *in_p = &((in_lwobj)->start_block); *in_p != NULL && (*in_p)->next < in_b;
         *in_pp = (*in_p), *in_p = (*in_p)->next) {}
}

/**
 * \brief           Set block as allocated
 * \param[in]       block: Block to set as allocated
 */
static void
prv_block_set_alloc(lwmem_block_t* block) {
    if (block != NULL) {
        block->size |= LWMEM_ALLOC_BIT;
        block->next = (void*)(LWMEM_TO_BYTE_PTR(0) + LWMEM_BLOCK_ALLOC_MARK);
    }
}

/**
 * \brief           Get region aligned start address and aligned size
 * \param[in]       region: Region to check for size and address
 * \param[out]      msa: Memory start address output variable
 * \param[out]      msz: Memory size output variable
 * \return          `1` if region valid, `0` otherwise
 */
static uint8_t
prv_get_region_addr_size(const lwmem_region_t* region, uint8_t** msa, size_t* msz) {
    size_t mem_size = 0;
    uint8_t* mem_start_addr = NULL;

    if (region == NULL || msa == NULL || msz == NULL) {
        return 0;
    }
    *msa = NULL;
    *msz = 0;

    /*
     * Start address must be aligned to configuration
     * Increase start address and decrease effective region size
     */
    mem_start_addr = region->start_addr;
    mem_size = region->size;
    if (((size_t)mem_start_addr) & LWMEM_ALIGN_BITS) { /* Check alignment boundary */
        mem_start_addr += ((size_t)LWMEM_CFG_ALIGN_NUM) - ((size_t)mem_start_addr & LWMEM_ALIGN_BITS);
        mem_size -= (size_t)(mem_start_addr - LWMEM_TO_BYTE_PTR(region->start_addr));
    }

    /* Check region size and align it to config bits */
    mem_size &= ~LWMEM_ALIGN_BITS; /* Align the size to lower bits */
    if (mem_size < (2 * LWMEM_BLOCK_MIN_SIZE)) {
        return 0;
    }

    /* Check final memory size */
    if (mem_size >= (2 * LWMEM_BLOCK_MIN_SIZE)) {
        *msa = mem_start_addr;
        *msz = mem_size;

        return 1;
    }
    return 0;
}

/**
 * \brief           Insert free block to linked list of free blocks
 * \param[in]       lwobj: LwMEM instance. Set to `NULL` to use default instance
 * \param[in]       nblk: New free block to insert into linked list
 */
static void
prv_insert_free_block(lwmem_t* const lwobj, lwmem_block_t* nblk) {
    lwmem_block_t* prev;

    /* Check valid inputs */
    if (nblk == NULL) {
        return;
    }

    /*
     * Try to find position to put new block in-between
     * Search until all free block addresses are lower than entry block
     */
    for (prev = &(lwobj->start_block); prev != NULL && prev->next != NULL && prev->next < nblk; prev = prev->next) {}

    /* This is hard error with wrong memory usage */
    if (prev == NULL) {
        return;
    }

    /*
     * At this point we have valid previous block
     * Previous block is last free block before input block
     */

#if LWMEM_CFG_CLEAN_MEMORY
    /*
     * Reset user memory. This is to reset memory
     * after it has been freed by the application.
     *
     * By doing this, we protect data left by app
     * and we make sure new allocations cannot see old information
     */
    if (nblk != NULL) {
        void* ptr = LWMEM_GET_PTR_FROM_BLOCK(nblk);
        if (ptr != NULL) {
            LWMEM_MEMSET(ptr, 0x00, nblk->size - LWMEM_BLOCK_META_SIZE);
        }
    }
#endif /* LWMEM_CFG_RESET_MEMORY */

    /*
     * Check if previous block and input block together create one big contiguous block
     * If this is the case, merge blocks together and increase previous block by input block size
     */
    if ((LWMEM_TO_BYTE_PTR(prev) + prev->size) == LWMEM_TO_BYTE_PTR(nblk)) {
        prev->size += nblk->size; /* Increase current block by size of new block */
        nblk = prev;              /* New block and current are now the same thing */
        /*
         * It is important to set new block as current one
         * as this allows merging previous and next blocks together with new block
         * at the same time; follow next steps
         */
    }

    /*
     * Check if new block and next of previous create big contiguous block
     * Do not merge with "end of region" indication (commented part of if statement)
     */
    if (prev->next != NULL && prev->next->size > 0 /* Do not remove "end of region" indicator in each region */
        && (LWMEM_TO_BYTE_PTR(nblk) + nblk->size) == LWMEM_TO_BYTE_PTR(prev->next)) {
        if (prev->next == lwobj->end_block) { /* Does it points to the end? */
            nblk->next = lwobj->end_block;    /* Set end block pointer */
        } else {
            /* Expand of current block for size of next free block which is right behind new block */
            nblk->size += prev->next->size;
            nblk->next = prev->next->next; /* Next free is pointed to the next one of previous next */
        }
    } else {
        nblk->next = prev->next; /* Set next of input block as next of current one */
    }

    /*
     * If new block has not been set as current (and expanded),
     * then link them together, otherwise ignore as it would point to itself
     */
    if (prev != nblk) {
        prev->next = nblk;
    }
}

/**
 * \brief           Split too big block and add it to list of free blocks
 * \param[in]       lwobj: LwMEM instance. Set to `NULL` to use default instance
 * \param[in]       block: Pointer to block with size already set
 * \param[in]       new_block_size: New block size to be set
 * \return          `1` if block splitted, `0` otherwise
 */
static uint8_t
prv_split_too_big_block(lwmem_t* const lwobj, lwmem_block_t* block, size_t new_block_size) {
    lwmem_block_t* next;
    size_t block_size, is_alloc_bit;
    uint8_t success = 0;

    is_alloc_bit = block->size & LWMEM_ALLOC_BIT; /* Check if allocation bit is set */
    block_size = block->size & ~LWMEM_ALLOC_BIT;  /* Use size without allocated bit */

    /*
     * If current block size is greater than requested size,
     * it is possible to create empty block at the end of existing one
     * and add it back to list of empty blocks
     */
    if ((block_size - new_block_size) >= LWMEM_BLOCK_MIN_SIZE) {
        next = (void*)(LWMEM_TO_BYTE_PTR(block) + new_block_size); /* Put next block after size of current allocation */
        next->size = block_size - new_block_size;                  /* Modify block data */
        block->size = new_block_size;                              /* Current size is now smaller */

        lwobj->mem_available_bytes += next->size; /* Increase available bytes by new block size */
        prv_insert_free_block(lwobj, next);       /* Add new block to the free list */

        success = 1;
    } else {
        /* TODO: If next of current is free, check if we can increase next by at least some bytes */
        /* This can only happen during reallocation process when allocated block is reallocated to previous one */
        /* Very rare case, but may happen! */
    }

    /* If allocation bit was set before, set it now again */
    if (is_alloc_bit) {
        prv_block_set_alloc(block);
    }
    return success;
}

/**
 * \brief           Private allocation function
 * \param[in]       lwobj: LwMEM instance. Set to `NULL` to use default instance
 * \param[in]       region: Pointer to region to allocate from.
 *                      Set to `NULL` for any region
 * \param[in]       size: Application wanted size, excluding size of meta header
 * \return          Pointer to allocated memory, `NULL` otherwise
 */
static void*
prv_alloc(lwmem_t* const lwobj, const lwmem_region_t* region, const size_t size) {
    lwmem_block_t *prev, *curr;
    void* retval = NULL;

    /* Calculate final size including meta data size */
    const size_t final_size = LWMEM_ALIGN(size) + LWMEM_BLOCK_META_SIZE;

    /* Check if initialized and if size is in the limits */
    if (lwobj->end_block == NULL || final_size == LWMEM_BLOCK_META_SIZE || (final_size & LWMEM_ALLOC_BIT) > 0) {
        return NULL;
    }

    /* Set default values */
    prev = &(lwobj->start_block); /* Use pointer from custom lwmem block */
    curr = prev->next;            /* Curr represents first actual free block */

    /*
     * If region is not set to NULL,
     * request for memory allocation came from specific region:
     *
     * - Start at the beginning like normal (from very first region)
     * - Loop until free block is between region start addr and its size
     */
    if (region != NULL) {
        uint8_t* region_start_addr;
        size_t region_size;

        /* Get data about region */
        if (!prv_get_region_addr_size(region, &region_start_addr, &region_size)) {
            return NULL;
        }

        /*
         * Scan all regions from lwmem and find first available block
         * which is within address of region and is big enough
         */
        for (; curr != NULL; prev = curr, curr = curr->next) {
            /* Check bounds */
            if (curr->next == NULL || curr == lwobj->end_block) {
                return NULL;
            }
            if ((uint8_t*)curr < (uint8_t*)region_start_addr) { /* Check if we reached region */
                continue;
            }
            if ((uint8_t*)curr >= (uint8_t*)(region_start_addr + region_size)) { /* Check if we are out already */
                return NULL;
            }
            if (curr->size >= final_size) {
                break; /* Free block identified */
            }
        }
    } else {
        /*
         * Try to find first block with at least `size` bytes of available memory
         * Loop until size of current block is smaller than requested final size
         */
        for (; curr != NULL && curr->size < final_size; prev = curr, curr = curr->next) {
            if (curr->next == NULL || curr == lwobj->end_block) { /* If no more blocks available */
                return NULL; /* No sufficient memory available to allocate block of memory */
            }
        }
    }

    /* Check curr pointer. During normal use, this should be always false */
    if (curr == NULL) {
        return NULL;
    }

    /* There is a valid block available */
    retval = LWMEM_GET_PTR_FROM_BLOCK(curr); /* Return pointer does not include meta part */
    prev->next = curr->next; /* Remove this block from linked list by setting next of previous to next of current */

    /* curr block is now removed from linked list */

    lwobj->mem_available_bytes -= curr->size;         /* Decrease available bytes by allocated block size */
    prv_split_too_big_block(lwobj, curr, final_size); /* Split block if it is too big */
    prv_block_set_alloc(curr);                        /* Set block as allocated */

    LWMEM_UPDATE_MIN_FREE(lwobj);
    LWMEM_INC_STATS(lwobj->stats.nr_alloc);

    return retval;
}

/**
 * \brief           Free input pointer
 * \param[in]       lwobj: LwMEM instance. Set to `NULL` to use default instance
 * \param[in]       ptr: Input pointer to free
 */
static void
prv_free(lwmem_t* const lwobj, void* const ptr) {
    lwmem_block_t* const block = LWMEM_GET_BLOCK_FROM_PTR(ptr);
    if (LWMEM_BLOCK_IS_ALLOC(block)) {   /* Check if block is valid */
        block->size &= ~LWMEM_ALLOC_BIT; /* Clear allocated bit indication */

        lwobj->mem_available_bytes += block->size; /* Increase available bytes */
        prv_insert_free_block(lwobj, block);       /* Put block back to list of free block */

        LWMEM_INC_STATS(lwobj->stats.nr_free);
    }
}

/**
 * \brief           Reallocates already allocated memory with new size
 *
 * Function behaves differently, depends on input parameter of `ptr` and `size`:
 *
 *  - `ptr == NULL; size == 0`: Function returns `NULL`, no memory is allocated or freed
 *  - `ptr == NULL; size > 0`: Function tries to allocate new block of memory with `size` length, equivalent to `malloc(size)`
 *  - `ptr != NULL; size == 0`: Function frees memory, equivalent to `free(ptr)`
 *  - `ptr != NULL; size > 0`: Function tries to allocate new memory of copy content before returning pointer on success
 *
 * \param[in]       lwobj: LwMEM instance. Set to `NULL` to use default instance
 * \param[in]       region: Pointer to region to allocate from.
 *                      Set to `NULL` for any region
 * \param[in]       ptr: Memory block previously allocated with one of allocation functions.
 *                      It may be set to `NULL` to create new clean allocation
 * \param[in]       size: Size of new memory to reallocate
 * \return          Pointer to allocated memory on success, `NULL` otherwise
 */
static void*
prv_realloc(lwmem_t* const lwobj, const lwmem_region_t* region, void* const ptr, const size_t size) {
    lwmem_block_t *block = NULL, *prevprev = NULL, *prev = NULL;
    size_t block_size; /* Holds size of input block (ptr), including metadata size */
    const size_t final_size =
        LWMEM_ALIGN(size) + LWMEM_BLOCK_META_SIZE; /* Holds size of new requested block size, including metadata size */
    void* retval;                                  /* Return pointer, used with LWMEM_RETURN macro */

    /* Check optional input parameters */
    if (size == 0) {
        if (ptr != NULL) {
            prv_free(lwobj, ptr);
        }
        return NULL;
    }
    if (ptr == NULL) {
        return prv_alloc(lwobj, region, size);
    }

    /* Try to reallocate existing pointer */
    if ((size & LWMEM_ALLOC_BIT) || (final_size & LWMEM_ALLOC_BIT)) {
        return NULL;
    }

    /* Process existing block */
    block = LWMEM_GET_BLOCK_FROM_PTR(ptr);
    if (!LWMEM_BLOCK_IS_ALLOC(block)) {

        /* Hard error. Input pointer is not NULL and block is not considered allocated */
        return NULL;
    }
    block_size = block->size & ~LWMEM_ALLOC_BIT; /* Get actual block size, without memory allocation bit */

    /* Check current block size is the same as new requested size */
    if (block_size == final_size) {
        return ptr; /* Just return pointer, nothing to do */
    }

    /*
     * Abbreviations
     *
     * - "Current block" or "Input block" is allocated block from input variable "ptr"
     * - "Next free block" is next free block, on address space after input block
     * - "Prev free block" is last free block, on address space before input block
     * - "PrevPrev free block" is previous free block of "Prev free block"
     */

    /*
     * When new requested size is smaller than existing one,
     * it is enough to modify size of current block only.
     *
     * If new requested size is much smaller than existing one,
     * check if it is possible to create new empty block and add it to list of empty blocks
     *
     * Application returns same pointer
     */
    if (final_size < block_size) {
        if ((block_size - final_size) >= LWMEM_BLOCK_MIN_SIZE) {
            prv_split_too_big_block(lwobj, block, final_size); /* Split block if it is too big */
        } else {
            /*
             * It is not possible to create new empty block at the end of input block
             *
             * But if next free block is just after input block,
             * it is possible to find this block and increase it by "block_size - final_size" bytes
             */

            /* Find free blocks before input block */
            prv_get_prev_curr_of_block(lwobj, block, &prevprev, &prev);

            /* Check if current block and next free are connected */
            if ((LWMEM_TO_BYTE_PTR(block) + block_size) == LWMEM_TO_BYTE_PTR(prev->next)
                && prev->next->size > 0) { /* Must not be end of region indicator */
                /* Make temporary variables as prev->next will point to different location */
                const size_t tmp_size = prev->next->size;
                void* const tmp_next = prev->next->next;

                /* Shift block up, effectively increase its size */
                prev->next = (void*)(LWMEM_TO_BYTE_PTR(prev->next) - (block_size - final_size));
                prev->next->size = tmp_size + (block_size - final_size);
                prev->next->next = tmp_next;

                /* Increase available bytes by increase of free block */
                lwobj->mem_available_bytes += block_size - final_size;

                block->size = final_size; /* Block size is requested size */
            }
        }
        prv_block_set_alloc(block); /* Set block as allocated */
        return ptr;                 /* Return existing pointer */
    }

    /* New requested size is bigger than current block size is */

    /* Find last free (and its previous) block, located just before input block */
    prv_get_prev_curr_of_block(lwobj, block, &prevprev, &prev);

    /* If entry could not be found, there is a hard error */
    if (prev == NULL) {
        return NULL;
    }

    /* Order of variables is: | prevprev ---> prev --->--->--->--->--->--->--->--->--->---> prev->next  | */
    /*                        |                      (input_block, which is not on a list)              | */
    /* Input block points to address somewhere between "prev" and "prev->next" pointers                   */

    /* Check if "block" and next free "prev->next" create contiguous memory with size of at least new requested size */
    if ((LWMEM_TO_BYTE_PTR(block) + block_size) == LWMEM_TO_BYTE_PTR(prev->next)
        && (block_size + prev->next->size) >= final_size) {

        /*
         * Merge blocks together by increasing current block with size of next free one
         * and remove next free from list of free blocks
         */
        lwobj->mem_available_bytes -= prev->next->size; /* For now decrease effective available bytes */
        LWMEM_UPDATE_MIN_FREE(lwobj);
        block->size = block_size + prev->next->size; /* Increase effective size of new block */
        prev->next = prev->next->next;               /* Set next to next's next,
                                                            effectively remove expanded block from free list */

        prv_split_too_big_block(lwobj, block, final_size); /* Split block if it is too big */
        prv_block_set_alloc(block);                        /* Set block as allocated */
        return ptr;                                        /* Return existing pointer */
    }

    /*
     * Check if "block" and last free before "prev" create contiguous memory with size of at least new requested size.
     *
     * It is necessary to make a memory move and shift content up as new return pointer is now upper on address space
     */
    if ((LWMEM_TO_BYTE_PTR(prev) + prev->size) == LWMEM_TO_BYTE_PTR(block) && (prev->size + block_size) >= final_size) {
        /* Move memory from block to block previous to current */
        void* const old_data_ptr = LWMEM_GET_PTR_FROM_BLOCK(block);
        void* const new_data_ptr = LWMEM_GET_PTR_FROM_BLOCK(prev);

        /*
         * If memmove overwrites metadata of current block (when shifting content up),
         * it is not an issue as we know its size (block_size) and next is already NULL.
         *
         * Memmove must be used to guarantee move of data as addresses + their sizes may overlap
         *
         * Metadata of "prev" are not modified during memmove
         */
        LWMEM_MEMMOVE(new_data_ptr, old_data_ptr, block_size);

        lwobj->mem_available_bytes -= prev->size; /* For now decrease effective available bytes */
        LWMEM_UPDATE_MIN_FREE(lwobj);
        prev->size += block_size;    /* Increase size of input block size */
        prevprev->next = prev->next; /* Remove prev from free list as it is now being used
                                                for allocation together with existing block */
        block = prev;                /* Move block pointer to previous one */

        prv_split_too_big_block(lwobj, block, final_size); /* Split block if it is too big */
        prv_block_set_alloc(block);                        /* Set block as allocated */
        return new_data_ptr;                               /* Return new data ptr */
    }

    /*
     * At this point, it was not possible to expand existing block with free before or free after due to:
     * - Input block & next free block do not create contiguous block or its new size is too small
     * - Previous free block & input block do not create contiguous block or its new size is too small
     *
     * Last option is to check if previous free block "prev", input block "block" and next free block "prev->next" create contiguous block
     * and size of new block (from 3 contiguous blocks) together is big enough
     */
    if ((LWMEM_TO_BYTE_PTR(prev) + prev->size) == LWMEM_TO_BYTE_PTR(block)
        && (LWMEM_TO_BYTE_PTR(block) + block_size) == LWMEM_TO_BYTE_PTR(prev->next)
        && (prev->size + block_size + prev->next->size) >= final_size) {

        /* Move memory from block to block previous to current */
        void* const old_data_ptr = LWMEM_GET_PTR_FROM_BLOCK(block);
        void* const new_data_ptr = LWMEM_GET_PTR_FROM_BLOCK(prev);

        /*
         * If memmove overwrites metadata of current block (when shifting content up),
         * it is not an issue as we know its size (block_size) and next is already NULL.
         *
         * Memmove must be used to guarantee move of data as addresses and their sizes may overlap
         *
         * Metadata of "prev" are not modified during memmove
         */
        LWMEM_MEMMOVE(new_data_ptr, old_data_ptr, block_size);

        /* Decrease effective available bytes for free blocks before and after input block */
        lwobj->mem_available_bytes -= prev->size + prev->next->size;
        LWMEM_UPDATE_MIN_FREE(lwobj);
        prev->size += block_size + prev->next->size; /* Increase size of new block by size of 2 free blocks */

        /* Remove free block before current one and block after current one from linked list (remove 2) */
        prevprev->next = prev->next->next;
        block = prev; /* Previous block is now current */

        prv_split_too_big_block(lwobj, block, final_size); /* Split block if it is too big */
        prv_block_set_alloc(block);                        /* Set block as allocated */
        return new_data_ptr;                               /* Return new data ptr */
    }

    /*
     * If application reaches this point, it means:
     * - New requested size is greater than input block size
     * - Input block & next free block do not create contiguous block or its new size is too small
     * - Last free block & input block do not create contiguous block or its new size is too small
     * - Last free block & input block & next free block do not create contiguous block or its size is too small
     *
     * Final solution is to find completely new empty block of sufficient size and copy content from old one to new one
     */
    retval = prv_alloc(lwobj, region, size); /* Try to allocate new block */
    if (retval != NULL) {
        /* Get application size from input pointer, then copy content to new block */
        block_size = (block->size & ~LWMEM_ALLOC_BIT) - LWMEM_BLOCK_META_SIZE;
        LWMEM_MEMCPY(retval, ptr, size > block_size ? block_size : size);
        prv_free(lwobj, ptr); /* Free old block */
    }
    return retval;
}

/**
 * \brief           Assign the memory structure for advanced memory allocation system
 * 
 * \param           lwobj 
 * \param           regions 
 * \return          size_t 
 */
static size_t
prv_assignmem(lwmem_t* lwobj, const lwmem_region_t* regions) {
    uint8_t* mem_start_addr = NULL;
    size_t mem_size = 0;
    lwmem_block_t *first_block = NULL, *prev_end_block = NULL;

    for (size_t idx = 0; regions->size > 0 && regions->start_addr != NULL; ++idx, ++regions) {
        /* Get region start address and size, stop on failure */
        if (!prv_get_region_addr_size(regions, &mem_start_addr, &mem_size)) {
            continue;
        }

        /*
         * If end_block == NULL, this indicates first iteration.
         * In first indication application shall set start_block and never again
         * end_block value holds
         */
        if (lwobj->end_block == NULL) {
            /*
             * Next entry of start block is first region
             * It points to beginning of region data
             * In the later step(s) first block is manually set on top of memory region
             */
            lwobj->start_block.next = (void*)mem_start_addr;
            lwobj->start_block.size = 0; /* Size of dummy start block is zero */
        }

        /* Save current end block status as it is used later for linked list insertion */
        prev_end_block = lwobj->end_block;

        /* Put end block to the end of the region with size = 0 */
        lwobj->end_block = (void*)(mem_start_addr + mem_size - LWMEM_BLOCK_META_SIZE);
        lwobj->end_block->next = NULL; /* End block in region does not have next entry */
        lwobj->end_block->size = 0;    /* Size of end block is zero */

        /*
         * Create memory region first block.
         *
         * First block meta size includes size of metadata too
         * Subtract MEM_BLOCK_META_SIZE as there is one more block (end_block) at the end of region
         *
         * Actual maximal available size for application in the region is mem_size - 2 * MEM_BLOCK_META_SIZE
         */
        first_block = (void*)mem_start_addr;
        first_block->next = lwobj->end_block; /* Next block of first is last block */
        first_block->size = mem_size - LWMEM_BLOCK_META_SIZE;

        /* Check if previous regions exist by checking previous end block state */
        if (prev_end_block != NULL) {
            prev_end_block->next = first_block; /* End block of previous region now points to start of current region */
        }

        lwobj->mem_available_bytes += first_block->size; /* Increase number of available bytes */
        ++lwobj->mem_regions_count;                      /* Increase number of used regions */
    }

#if defined(LWMEM_DEV)
    /* Copy default state of start block */
    LWMEM_MEMCPY(&lwmem_default.start_block_first_use, &lwmem_default.start_block, sizeof(lwmem_default.start_block));
#endif /* defined(LWMEM_DEV) */
#if LWMEM_CFG_ENABLE_STATS
    lwobj->stats.mem_size_bytes = lwobj->mem_available_bytes;
    lwobj->stats.minimum_ever_mem_available_bytes = lwobj->mem_available_bytes;
#endif

    return lwobj->mem_regions_count; /* Return number of regions used by manager */
}

#else /* LWMEM_CFG_FULL */

/**
 * \brief           Assign the regions for simple algorithm
 * 
 *                  At this point, regions check has been performed, so we assume
 *                  everything is ready to proceed
 * 
 * \param           lwobj: LwMEM object
 * \param           regions: List of regions to assign
 * \return          Number of regions used
 */
static size_t
prv_assignmem_simple(lwmem_t* const lwobj, const lwmem_region_t* regions) {
    uint8_t* mem_start_addr = regions[0].start_addr;
    size_t mem_size = regions[0].size;

    /* Adjust alignment data */
    if (((size_t)mem_start_addr) & LWMEM_ALIGN_BITS) {
        mem_start_addr += ((size_t)LWMEM_CFG_ALIGN_NUM) - ((size_t)mem_start_addr & LWMEM_ALIGN_BITS);
        mem_size -= (size_t)(mem_start_addr - LWMEM_TO_BYTE_PTR(regions[0].start_addr));
    }

    /* Align mem to alignment*/
    mem_size = mem_size & ~LWMEM_ALIGN_BITS;

    /* Store the available information */
    lwobj->mem_available_bytes = mem_size;
    lwobj->mem_next_available_ptr = mem_start_addr;
    lwobj->is_initialized = 1;
    return 1; /* One region is being used only for now */
}

/**
 * \brief           Simple allocation algorithm, that can only allocate memory,
 *                  but it does not support free.
 * 
 *                  It uses simple first-in-first-serve concept,
 *                  where memory grows upward gradually, up until it reaches the end
 *                  of memory area
 * 
 * \param           lwobj: LwMEM object
 * \param           region: Selected region. Not used in the current revision,
 *                      but footprint remains the same if one day library will support it
 * \param           size: Requested allocation size
 * \return          `NULL` on failure, or pointer to allocated memory
 */
static void*
prv_alloc_simple(lwmem_t* const lwobj, const lwmem_region_t* region, const size_t size) {
    void* retval = NULL;
    const size_t alloc_size = LWMEM_ALIGN(size);

    if (alloc_size <= lwobj->mem_available_bytes) {
        retval = lwobj->mem_next_available_ptr;

        /* Get ready for next iteration */
        lwobj->mem_next_available_ptr += alloc_size;
        lwobj->mem_available_bytes -= alloc_size;
    }
    (void)region;
    return retval;
}

#endif /* LWMEM_CFG_FULL */

/**
 * \brief           Initializes and assigns user regions for memory used by allocator algorithm
 * \param[in]       lwobj: LwMEM instance. Set to `NULL` to use default instance
 * \param[in]       regions: Pointer to array of regions with address and respective size.
 *                      Regions must be in increasing order (start address) and must not overlap in-between.
 *                      Last region entry must have address `NULL` and size set to `0`
 * \code{.c}
//Example definition
lwmem_region_t regions[] = {
    { (void *)0x10000000, 0x1000 }, //Region starts at address 0x10000000 and is 0x1000 bytes long
    { (void *)0x20000000, 0x2000 }, //Region starts at address 0x20000000 and is 0x2000 bytes long
    { (void *)0x30000000, 0x3000 }, //Region starts at address 0x30000000 and is 0x3000 bytes long
    { NULL, 0 }                     //Array termination indicator
}
\endcode
 * \return          `0` on failure, number of final regions used for memory manager on success
 * \note            This function is not thread safe when used with operating system.
 *                      It must be called only once to setup memory regions
 */
size_t
lwmem_assignmem_ex(lwmem_t* lwobj, const lwmem_region_t* regions) {
    uint8_t* mem_start_addr = NULL;
    size_t mem_size = 0, len = 0;

    lwobj = LWMEM_GET_LWOBJ(lwobj);

    /* Check first things first */
    if (regions == NULL
#if LWMEM_CFG_FULL
        || lwobj->end_block != NULL /* Init function may only be called once per lwmem instance */
#else
        || lwobj->is_initialized /* Already initialized? */
#endif /* LWMEM_CFG_FULL */
    ) {
        return 0;
    }

    /* Check values entered by application */
    mem_start_addr = (void*)0;
    mem_size = 0;
    for (size_t idx = 0;; ++idx) {
        /*
         * Check for valid entry or end of array descriptor
         * Invalid entry is considered as "end-of-region" indicator
         */
        if (regions[idx].size == 0 && regions[idx].start_addr == NULL) {
            len = idx;
            if (len == 0) {
                return 0;
            }
            break;
        }

#if !LWMEM_CFG_FULL
        /*
         * In case of simple allocation algorithm, we (for now!) only allow one region.
         * Return zero value if user passed more than one region in a sequence.
         */
        else if (idx > 0) {
            return 0;
        }
#endif /* LWMEM_CFG_FULL */

        /* New region(s) must be higher (in address space) than previous one */
        if ((mem_start_addr + mem_size) > LWMEM_TO_BYTE_PTR(regions[idx].start_addr)) {
            return 0;
        }

        /* Save new values for next round */
        mem_start_addr = regions[idx].start_addr;
        mem_size = regions[idx].size;
    }

    /* Final init and check before initializing the regions */
    if (len == 0
#if LWMEM_CFG_OS
        // || lwmem_sys_mutex_isvalid(&(lwobj->mutex)) /* Check if mutex valid already = must not be */
        || !lwmem_sys_mutex_create(&(lwobj->mutex)) /* Final step = try to create mutex for new instance */
#endif                                              /* LWMEM_CFG_OS */
    ) {
        return 0;
    }

#if LWMEM_CFG_FULL
    return prv_assignmem(lwobj, regions);
#else  /* LWMEM_CFG_FULL */
    return prv_assignmem_simple(lwobj, regions);
#endif /* LWMEM_CFG_FULL */
}

/**
 * \brief           Allocate memory of requested size in specific lwmem instance and optional region.
 * \note            This is an extended malloc version function declaration to support advanced features
 * \param[in]       lwobj: LwMEM instance. Set to `NULL` to use default instance
 * \param[in]       region: Optional region instance within LwMEM instance to force allocation from.
 *                      Set to `NULL` to use any region within LwMEM instance
 * \param[in]       size: Number of bytes to allocate
 * \return          Pointer to allocated memory on success, `NULL` otherwise
 * \note            This function is thread safe when \ref LWMEM_CFG_OS is enabled
 */
void*
lwmem_malloc_ex(lwmem_t* lwobj, const lwmem_region_t* region, const size_t size) {
    void* ptr = NULL;

    lwobj = LWMEM_GET_LWOBJ(lwobj);

    LWMEM_PROTECT(lwobj);
#if LWMEM_CFG_FULL
    ptr = prv_alloc(lwobj, region, size);
#else  /* LWMEM_CFG_FULL */
    ptr = prv_alloc_simple(lwobj, region, size);
#endif /* LWMEM_CFG_FULL */
    LWMEM_UNPROTECT(lwobj);
    return ptr;
}

/**
 * \brief           Allocate contiguous block of memory for requested number of items and its size
 *                  in specific lwmem instance and region.
 *
 * It resets allocated block of memory to zero if allocation is successful
 *
 * \note            This is an extended calloc version function declaration to support advanced features
 * \param[in]       lwobj: LwMEM instance. Set to `NULL` to use default instance
 * \param[in]       region: Optional region instance within LwMEM instance to force allocation from.
 *                      Set to `NULL` to use any region within LwMEM instance
 * \param[in]       nitems: Number of elements to be allocated
 * \param[in]       size: Size of each element, in units of bytes
 * \return          Pointer to allocated memory on success, `NULL` otherwise
 * \note            This function is thread safe when \ref LWMEM_CFG_OS is enabled
 */
void*
lwmem_calloc_ex(lwmem_t* lwobj, const lwmem_region_t* region, const size_t nitems, const size_t size) {
    void* ptr = NULL;
    const size_t alloc_size = size * nitems;

    lwobj = LWMEM_GET_LWOBJ(lwobj);

    LWMEM_PROTECT(lwobj);
#if LWMEM_CFG_FULL
    ptr = prv_alloc(lwobj, region, alloc_size);
#else  /* LWMEM_CFG_FULL */
    ptr = prv_alloc_simple(lwobj, region, alloc_size);
#endif /* LWMEM_CFG_FULL */
    LWMEM_UNPROTECT(lwobj);

    if (ptr != NULL) {
        LWMEM_MEMSET(ptr, 0x00, alloc_size);
    }
    return ptr;
}

#if LWMEM_CFG_FULL || __DOXYGEN__

/**
 * \brief           Reallocates already allocated memory with new size in specific lwmem instance and region.
 *
 * \note            This function may only be used with allocations returned by any of `_from` API functions
 *
 * Function behaves differently, depends on input parameter of `ptr` and `size`:
 *
 *  - `ptr == NULL; size == 0`: Function returns `NULL`, no memory is allocated or freed
 *  - `ptr == NULL; size > 0`: Function tries to allocate new block of memory with `size` length, equivalent to `malloc(region, size)`
 *  - `ptr != NULL; size == 0`: Function frees memory, equivalent to `free(ptr)`
 *  - `ptr != NULL; size > 0`: Function tries to allocate new memory of copy content before returning pointer on success
 *
 * \param[in]       lwobj: LwMEM instance. Set to `NULL` to use default instance
 * \param[in]       region: Pointer to region to allocate from.
 *                      Set to `NULL` to use any region within LwMEM instance.
 *                      Instance must be the same as used during allocation procedure
 * \param[in]       ptr: Memory block previously allocated with one of allocation functions.
 *                      It may be set to `NULL` to create new clean allocation
 * \param[in]       size: Size of new memory to reallocate
 * \return          Pointer to allocated memory on success, `NULL` otherwise
 * \note            This function is thread safe when \ref LWMEM_CFG_OS is enabled
 */
void*
lwmem_realloc_ex(lwmem_t* lwobj, const lwmem_region_t* region, void* const ptr, const size_t size) {
    void* p;
    lwobj = LWMEM_GET_LWOBJ(lwobj);
    LWMEM_PROTECT(lwobj);
    p = prv_realloc(lwobj, region, ptr, size);
    LWMEM_UNPROTECT(lwobj);
    return p;
}

/**
 * \brief           Safe version of realloc_ex function.
 *
 * After memory is reallocated, input pointer automatically points to new memory
 * to prevent use of dangling pointers. When reallocation is not successful,
 * original pointer is not modified and application still has control of it.
 *
 * It is advised to use this function when reallocating memory.
 *
 * Function behaves differently, depends on input parameter of `ptr` and `size`:
 *
 *  - `ptr == NULL`: Invalid input, function returns `0`
 *  - `*ptr == NULL; size == 0`: Function returns `0`, no memory is allocated or freed
 *  - `*ptr == NULL; size > 0`: Function tries to allocate new block of memory with `size` length, equivalent to `malloc(size)`
 *  - `*ptr != NULL; size == 0`: Function frees memory, equivalent to `free(ptr)`, sets input pointer pointing to `NULL`
 *  - `*ptr != NULL; size > 0`: Function tries to reallocate existing pointer with new size and copy content to new block
 *
 * \param[in]       lwobj: LwMEM instance. Set to `NULL` to use default instance
 * \param[in]       region: Pointer to region to allocate from.
 *                      Set to `NULL` to use any region within LwMEM instance.
 *                      Instance must be the same as used during allocation procedure
 * \param[in]       ptr: Pointer to pointer to allocated memory. Must not be set to `NULL`.
 *                      If reallocation is successful, it modifies pointer's pointing address,
 *                      or sets it to `NULL` in case of `free` operation
 * \param[in]       size: New requested size in bytes
 * \return          `1` if successfully reallocated, `0` otherwise
 * \note            This function is thread safe when \ref LWMEM_CFG_OS is enabled
 */
int
lwmem_realloc_s_ex(lwmem_t* lwobj, const lwmem_region_t* region, void** const ptr, const size_t size) {
    void* new_ptr;

    /*
     * Input pointer must not be NULL otherwise,
     * in case of successful allocation, we have memory leakage
     * aka. allocated memory where noone is pointing to it
     */
    if (ptr == NULL) {
        return 0;
    }

    new_ptr = lwmem_realloc_ex(lwobj, region, *ptr, size); /* Try to reallocate existing pointer */
    if (new_ptr != NULL) {
        *ptr = new_ptr;
    } else if (size == 0) { /* size == 0 means free input memory */
        *ptr = NULL;
        return 1;
    }
    return new_ptr != NULL;
}

/**
 * \brief           Free previously allocated memory using one of allocation functions
 *                  in specific lwmem instance.
 * \param[in]       lwobj: LwMEM instance. Set to `NULL` to use default instance.
 *                      Instance must be the same as used during allocation procedure
 * \note            This is an extended free version function declaration to support advanced features
 * \param[in]       ptr: Memory to free. `NULL` pointer is valid input
 * \note            This function is thread safe when \ref LWMEM_CFG_OS is enabled
 */
void
lwmem_free_ex(lwmem_t* lwobj, void* const ptr) {
    lwobj = LWMEM_GET_LWOBJ(lwobj);
    LWMEM_PROTECT(lwobj);
    prv_free(lwobj, ptr);
    LWMEM_UNPROTECT(lwobj);
}

/**
 * \brief           Safe version of free function
 *
 * After memory is freed, input pointer is safely set to `NULL`
 * to prevent use of dangling pointers.
 *
 * It is advised to use this function when freeing memory.
 *
 * \param[in]       lwobj: LwMEM instance. Set to `NULL` to use default instance.
 *                      Instance must be the same as used during allocation procedure
 * \param[in]       ptr: Pointer to pointer to allocated memory.
 *                  When set to non `NULL`, pointer is freed and set to `NULL`
 * \note            This function is thread safe when \ref LWMEM_CFG_OS is enabled
 */
void
lwmem_free_s_ex(lwmem_t* lwobj, void** const ptr) {
    if (ptr != NULL && *ptr != NULL) {
        lwobj = LWMEM_GET_LWOBJ(lwobj);
        LWMEM_PROTECT(lwobj);
        prv_free(lwobj, *ptr);
        LWMEM_UNPROTECT(lwobj);
        *ptr = NULL;
    }
}

/**
 * \brief           Get user size of allocated memory
 * \param[in]       lwobj: LwMEM instance. Set to `NULL` to use default instance.
 *                      Instance must be the same as used during allocation procedure
 * \param[in]       ptr: Pointer to allocated memory
 * \return          Block size for user in units of bytes
 */
size_t
lwmem_get_size_ex(lwmem_t* lwobj, void* ptr) {
    lwmem_block_t* block;
    uint32_t len = 0;

    if (ptr != NULL) {
        lwobj = LWMEM_GET_LWOBJ(lwobj);
        LWMEM_PROTECT(lwobj);
        block = LWMEM_GET_BLOCK_FROM_PTR(ptr);
        if (LWMEM_BLOCK_IS_ALLOC(block)) {
            len = (block->size & ~LWMEM_ALLOC_BIT) - LWMEM_BLOCK_META_SIZE;
        }
        LWMEM_UNPROTECT(lwobj);
    }
    return len;
}

#endif /* LWMEM_CFG_FULL || __DOXYGEN__ */

#if LWMEM_CFG_ENABLE_STATS || __DOXYGEN__

/**
 * \brief           Get statistics of a LwMEM instance
 * \param[in]       lwobj: LwMEM instance. Set to `NULL` to use default instance.
 *                      Instance must be the same as used during allocation procedure
 * \param[in,out]   stats: Pointer to \ref lwmem_stats_t to store result
 */
void
lwmem_get_stats_ex(lwmem_t* lwobj, lwmem_stats_t* stats) {
    if (stats != NULL) {
        lwobj = LWMEM_GET_LWOBJ(lwobj);
        LWMEM_PROTECT(lwobj);
        *stats = lwobj->stats;
        stats->mem_available_bytes = lwobj->mem_available_bytes;
        LWMEM_UNPROTECT(lwobj);
    }
}

/**
 * \brief           Get statistics of a default LwMEM instance
 * \param[in,out]   stats: Pointer to \ref lwmem_stats_t to store result
 */
void
lwmem_get_stats(lwmem_stats_t* stats) {
    lwmem_get_stats_ex(NULL, stats);
}

#endif /* LWMEM_CFG_ENABLE_STATS || __DOXYGEN__ */

/**
 * \note            This is a wrapper for \ref lwmem_assignmem_ex function.
 *                      It operates in default LwMEM instance and uses first available region for memory operations
 * \param[in]       regions: Pointer to array of regions with address and respective size.
 *                      Regions must be in increasing order (start address) and must not overlap in-between.
 *                      Last region entry must have address `NULL` and size set to `0`
 * \code{.c}
//Example definition
lwmem_region_t regions[] = {
    { (void *)0x10000000, 0x1000 }, //Region starts at address 0x10000000 and is 0x1000 bytes long
    { (void *)0x20000000, 0x2000 }, //Region starts at address 0x20000000 and is 0x2000 bytes long
    { (void *)0x30000000, 0x3000 }, //Region starts at address 0x30000000 and is 0x3000 bytes long
    { NULL, 0 }                     //Array termination indicator
}
\endcode
 * \return          `0` on failure, number of final regions used for memory manager on success
 */
size_t
lwmem_assignmem(const lwmem_region_t* regions) {
    return lwmem_assignmem_ex(NULL, regions);
}

/**
 * \note            This is a wrapper for \ref lwmem_malloc_ex function.
 *                      It operates in default LwMEM instance and uses first available region for memory operations
 * \param[in]       size: Size to allocate in units of bytes
 * \return          Pointer to allocated memory on success, `NULL` otherwise
 * \note            This function is thread safe when \ref LWMEM_CFG_OS is enabled
 */
void*
lwmem_malloc(size_t size) {
    return lwmem_malloc_ex(NULL, NULL, size);
}

/**
 * \note            This is a wrapper for \ref lwmem_calloc_ex function.
 *                      It operates in default LwMEM instance and uses first available region for memory operations
 * \param[in]       nitems: Number of elements to be allocated
 * \param[in]       size: Size of each element, in units of bytes
 * \return          Pointer to allocated memory on success, `NULL` otherwise
 * \note            This function is thread safe when \ref LWMEM_CFG_OS is enabled
 */
void*
lwmem_calloc(size_t nitems, size_t size) {
    return lwmem_calloc_ex(NULL, NULL, nitems, size);
}

#if LWMEM_CFG_FULL || __DOXYGEN__

/**
 * \note            This is a wrapper for \ref lwmem_realloc_ex function.
 *                      It operates in default LwMEM instance and uses first available region for memory operations
 * \param[in]       ptr: Memory block previously allocated with one of allocation functions.
 *                      It may be set to `NULL` to create new clean allocation
 * \param[in]       size: Size of new memory to reallocate
 * \return          Pointer to allocated memory on success, `NULL` otherwise
 * \note            This function is thread safe when \ref LWMEM_CFG_OS is enabled
 */
void*
lwmem_realloc(void* ptr, size_t size) {
    return lwmem_realloc_ex(NULL, NULL, ptr, size);
}

/**
 * \note            This is a wrapper for \ref lwmem_realloc_s_ex function.
 *                      It operates in default LwMEM instance and uses first available region for memory operations
 * \param[in]       ptr2ptr: Pointer to pointer to allocated memory. Must not be set to `NULL`.
 *                      If reallocation is successful, it modifies pointer's pointing address,
 *                      or sets it to `NULL` in case of `free` operation
 * \param[in]       size: New requested size in bytes
 * \return          `1` if successfully reallocated, `0` otherwise
 * \note            This function is thread safe when \ref LWMEM_CFG_OS is enabled
 */
int
lwmem_realloc_s(void** ptr2ptr, size_t size) {
    return lwmem_realloc_s_ex(NULL, NULL, ptr2ptr, size);
}

/**
 * \note            This is a wrapper for \ref lwmem_free_ex function.
 *                      It operates in default LwMEM instance and uses first available region for memory operations
 * \param[in]       ptr: Memory to free. `NULL` pointer is valid input
 * \note            This function is thread safe when \ref LWMEM_CFG_OS is enabled
 */
void
lwmem_free(void* ptr) {
    lwmem_free_ex(NULL, (ptr));
}

/**
 * \note            This is a wrapper for \ref lwmem_free_s_ex function.
 *                      It operates in default LwMEM instance and uses first available region for memory operations
 * \param[in]       ptr2ptr: Pointer to pointer to allocated memory.
 *                      When set to non `NULL`, pointer is freed and set to `NULL`
 * \note            This function is thread safe when \ref LWMEM_CFG_OS is enabled
 */
void
lwmem_free_s(void** ptr2ptr) {
    lwmem_free_s_ex(NULL, (ptr2ptr));
}

/**
 * \note            This is a wrapper for \ref lwmem_get_size_ex function.
 *                      It operates in default LwMEM instance and uses first available region for memory operations
 * \param[in]       ptr: Pointer to allocated memory
 * \return          Block size for user in units of bytes
 */
size_t
lwmem_get_size(void* ptr) {
    return lwmem_get_size_ex(NULL, ptr);
}

#endif /* LWMEM_CFG_FULL || __DOXYGEN__ */

/* Part of library used ONLY for LWMEM_DEV purposes */
/* To validate and test library */

#if defined(LWMEM_DEV) && LWMEM_CFG_FULL && !__DOXYGEN__

#include <stdio.h>
#include <stdlib.h>

/* Temporary variable for lwmem save */
static lwmem_t lwmem_temp;
static lwmem_region_t* regions_orig;
static lwmem_region_t* regions_temp;
static size_t regions_count;

static lwmem_region_t*
create_regions(size_t count, size_t size) {
    lwmem_region_t* regions;
    lwmem_region_t tmp;

    /*
     * Allocate pointer structure
     *
     * Length 1 entry more, to set default values for NULL entry
     */
    regions = calloc(count + 1, sizeof(*regions));
    if (regions == NULL) {
        return NULL;
    }

    /* Allocate memory for regions */
    for (size_t i = 0; i < count; ++i) {
        regions[i].size = size;
        regions[i].start_addr = malloc(regions[i].size);
        if (regions[i].start_addr == NULL) {
            return NULL;
        }
    }
    regions[count].size = 0;
    regions[count].start_addr = NULL;

    /* Sort regions, make sure they grow linearly */
    for (size_t x = 0; x < count; ++x) {
        for (size_t y = 0; y < count; ++y) {
            if (regions[x].start_addr < regions[y].start_addr) {
                memcpy(&tmp, &regions[x], sizeof(regions[x]));
                memcpy(&regions[x], &regions[y], sizeof(regions[x]));
                memcpy(&regions[y], &tmp, sizeof(regions[x]));
            }
        }
    }

    return regions;
}

static void
print_block(size_t i, lwmem_block_t* block) {
    size_t is_free, block_size;

    is_free = (block->size & LWMEM_ALLOC_BIT) == 0 && block != &lwmem_default.start_block_first_use && block->size > 0;
    block_size = block->size & ~LWMEM_ALLOC_BIT;

    printf("| %5d | %16p | %6d | %4d | %16d |", (int)i, (void*)block, (int)is_free, (int)block_size,
           (int)(is_free ? (block_size - LWMEM_BLOCK_META_SIZE) : 0));
    if (block == &lwmem_default.start_block_first_use) {
        printf(" Start block     ");
    } else if (block_size == 0) {
        printf(" End of region   ");
    } else if (is_free) {
        printf(" Free block      ");
    } else if (!is_free) {
        printf(" Allocated block ");
    } else {
        printf("                 ");
    }
    printf("|\r\n");
}

void
lwmem_debug_print(uint8_t print_alloc, uint8_t print_free) {
    size_t block_size;
    lwmem_block_t* block;

    (void)print_alloc;
    (void)print_free;

    printf("|-------|------------------|--------|------|------------------|-----------------|\r\n");
    printf("| Block |          Address | IsFree | Size | MaxUserAllocSize | Meta            |\r\n");
    printf("|-------|------------------|--------|------|------------------|-----------------|\r\n");

    block = &lwmem_default.start_block_first_use;
    print_block(0, &lwmem_default.start_block_first_use);
    printf("|-------|------------------|--------|------|------------------|-----------------|\r\n");
    for (size_t i = 0, j = 1; i < regions_count; ++i) {
        block = regions_orig[i].start_addr;

        /* Print all blocks */
        for (;; ++j) {
            block_size = block->size & ~LWMEM_ALLOC_BIT;

            print_block(j, block);

            /* Get next block */
            block = (void*)(LWMEM_TO_BYTE_PTR(block) + block_size);
            if (block_size == 0) {
                break;
            }
        }
        printf("|-------|------------------|--------|------|------------------|-----------------|\r\n");
    }
}

uint8_t
lwmem_debug_create_regions(lwmem_region_t** regs_out, size_t count, size_t size) {
    regions_orig = create_regions(count, size);
    regions_temp = create_regions(count, size);

    if (regions_orig == NULL || regions_temp == NULL) {
        return 0;
    }
    regions_count = count;
    *regs_out = regions_orig;

    return 1;
}

void
lwmem_debug_save_state(void) {
    memcpy(&lwmem_temp, &lwmem_default, sizeof(lwmem_temp));
    for (size_t i = 0; i < regions_count; ++i) {
        memcpy(regions_temp[i].start_addr, regions_orig[i].start_addr, regions_temp[i].size);
    }
    printf(" -- > Current state saved!\r\n");
}

void
lwmem_debug_restore_to_saved(void) {
    memcpy(&lwmem_default, &lwmem_temp, sizeof(lwmem_temp));
    for (size_t i = 0; i < regions_count; ++i) {
        memcpy(regions_orig[i].start_addr, regions_temp[i].start_addr, regions_temp[i].size);
    }
    printf(" -- > State restored to last saved!\r\n");
}

void
lwmem_debug_test_region(void* region_start, size_t region_size, uint8_t** region_start_calc, size_t* region_size_calc) {
    lwmem_region_t region = {
        .start_addr = region_start,
        .size = region_size,
    };
    prv_get_region_addr_size(&region, region_start_calc, region_size_calc);
}

#endif /* defined(LWMEM_DEV) && !__DOXYGEN__ */
