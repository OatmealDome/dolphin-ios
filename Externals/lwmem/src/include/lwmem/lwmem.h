/**
 * \file            lwmem.h
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
#ifndef LWMEM_HDR_H
#define LWMEM_HDR_H

#include <limits.h>
#include <stddef.h>
#include <stdint.h>
#include "lwmem/lwmem_opt.h"

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

/**
 * \defgroup        LWMEM Lightweight dynamic memory manager
 * \brief           Lightweight dynamic memory manager
 * \{
 */

/**
 * \brief           Get size of statically allocated array
 * \param[in]       x: Object to get array size of
 * \return          Number of elements in array
 */
#define LWMEM_ARRAYSIZE(x) (sizeof(x) / sizeof((x)[0]))

/**
 * \brief           Memory block structure
 */
typedef struct lwmem_block {
    struct lwmem_block* next; /*!< Next free memory block on linked list.
                                    Set to \ref LWMEM_BLOCK_ALLOC_MARK when block is allocated and in use */
    size_t size;              /*!< Size of block, including metadata part.
                                    MSB bit is set to `1` when block is allocated and in use,
                                    or `0` when block is considered free */
} lwmem_block_t;

/**
 * \brief           Statistics structure
 */
typedef struct {
    uint32_t mem_size_bytes;                   /*!< Total memory size of all regions combined */
    uint32_t mem_available_bytes;              /*!< Free memory available for allocation */
    uint32_t minimum_ever_mem_available_bytes; /*!< Minimum amount of total free memory there has been
                                                        in the heap since the system booted. */
    uint32_t nr_alloc;                         /*!< Number of all allocated blocks in single instance  */
    uint32_t nr_free;                          /*!< Number of frees in the LwMEM instance */
} lwmem_stats_t;

/**
 * \brief           LwMEM main structure
 */
typedef struct lwmem {
    size_t mem_available_bytes; /*!< Memory size available for allocation */
#if LWMEM_CFG_FULL
    lwmem_block_t start_block; /*!< Holds beginning of memory allocation regions */
    lwmem_block_t* end_block;  /*!< Pointer to the last memory location in regions linked list */
    size_t mem_regions_count;  /*!< Number of regions used for allocation */
#else
    uint8_t* mem_next_available_ptr; /*!< Pointer for next allocation */
    uint8_t is_initialized;          /*!< Set to `1` when initialized */
#endif

#if LWMEM_CFG_OS || __DOXYGEN__
    LWMEM_CFG_OS_MUTEX_HANDLE mutex; /*!< System mutex for OS */
#endif                               /* LWMEM_CFG_OS || __DOXYGEN__ */
#if LWMEM_CFG_ENABLE_STATS || __DOXYGEN__
    lwmem_stats_t stats; /*!< Statistics */
#endif                   /* LWMEM_CFG_ENABLE_STATS || __DOXYGEN__ */
#if defined(LWMEM_DEV) && !__DOXYGEN__
    lwmem_block_t start_block_first_use; /*!< Value of start block for very first time.
                                            This is used only during validation process and is removed in final use */
#endif                                   /* defined(LWMEM_DEV) && !__DOXYGEN__ */
} lwmem_t;

/**
 * \brief           Memory region descriptor
 */
typedef struct {
    void* start_addr; /*!< Region start address */
    size_t size;      /*!< Size of region in units of bytes */
} lwmem_region_t;

size_t lwmem_assignmem_ex(lwmem_t* lwobj, const lwmem_region_t* regions);
void* lwmem_malloc_ex(lwmem_t* lwobj, const lwmem_region_t* region, const size_t size);
void* lwmem_calloc_ex(lwmem_t* lwobj, const lwmem_region_t* region, const size_t nitems, const size_t size);
#if LWMEM_CFG_FULL || __DOXYGEN__
void* lwmem_realloc_ex(lwmem_t* lwobj, const lwmem_region_t* region, void* const ptr, const size_t size);
int lwmem_realloc_s_ex(lwmem_t* lwobj, const lwmem_region_t* region, void** const ptr, const size_t size);
void lwmem_free_ex(lwmem_t* lwobj, void* const ptr);
void lwmem_free_s_ex(lwmem_t* lwobj, void** const ptr);
size_t lwmem_get_size_ex(lwmem_t* lwobj, void* ptr);
#endif /* LWMEM_CFG_FULL || __DOXYGEN__ */
#if LWMEM_CFG_ENABLE_STATS || __DOXYGEN__
void lwmem_get_stats_ex(lwmem_t* lwobj, lwmem_stats_t* stats);
void lwmem_get_stats(lwmem_stats_t* stats);
#endif /* LWMEM_CFG_ENABLE_STATS || __DOXYGEN__ */

size_t lwmem_assignmem(const lwmem_region_t* regions);
void* lwmem_malloc(size_t size);
void* lwmem_calloc(size_t nitems, size_t size);

#if LWMEM_CFG_FULL || __DOXYGEN__
void* lwmem_realloc(void* ptr, size_t size);
int lwmem_realloc_s(void** ptr2ptr, size_t size);
void lwmem_free(void* ptr);
void lwmem_free_s(void** ptr2ptr);
size_t lwmem_get_size(void* ptr);
#endif /* LWMEM_CFG_FULL || __DOXYGEN__ */

#if defined(LWMEM_DEV) && !__DOXYGEN__
unsigned char lwmem_debug_create_regions(lwmem_region_t** regs_out, size_t count, size_t size);
void lwmem_debug_save_state(void);
void lwmem_debug_restore_to_saved(void);
void lwmem_debug_print(unsigned char print_alloc, unsigned char print_free);
void lwmem_debug_test_region(void* region_start, size_t region_size, uint8_t** region_start_calc,
                             size_t* region_size_calc);
#endif /* defined(LWMEM_DEV) && !__DOXYGEN__ */

/**
 * \}
 */

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* LWMEM_HDR_H */
