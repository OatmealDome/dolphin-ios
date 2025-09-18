/**
 * \file            lwmem_opt.h
 * \brief           LwMEM options
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
#ifndef LWMEM_OPT_HDR_H
#define LWMEM_OPT_HDR_H

/* Uncomment to ignore user options (or set macro in compiler flags) */
/* #define LWMEM_IGNORE_USER_OPTS */

/* Include application options */
#ifndef LWMEM_IGNORE_USER_OPTS
#include "lwmem_opts.h"
#endif /* LWMEM_IGNORE_USER_OPTS */

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

/**
 * \defgroup        LWMEM_OPT Configuration
 * \brief           LwMEM options
 * \{
 */

/**
 * \brief           Enables `1` or disables `0` operating system support in the library
 *
 * \note            When `LWMEM_CFG_OS` is enabled, user must implement functions in \ref LWMEM_SYS group.
 */
#ifndef LWMEM_CFG_OS
#define LWMEM_CFG_OS 0
#endif

/**
 * \brief           Mutex handle type
 *
 * \note            This value must be set in case \ref LWMEM_CFG_OS is set to `1`.
 *                  If data type is not known to compiler, include header file with
 *                  definition before you define handle type
 */
#ifndef LWMEM_CFG_OS_MUTEX_HANDLE
#define LWMEM_CFG_OS_MUTEX_HANDLE void*
#endif

/**
 * \brief           Number of bits to align memory address and memory size
 *
 * Some CPUs do not offer unaligned memory access (Cortex-M0 as an example)
 * therefore it is important to have alignment of data addresses and potentialy length of data
 *
 * \note            This value must be a power of `2` for number of bytes.
 *                  Usually alignment of `4` bytes fits to all processors.
 */
#ifndef LWMEM_CFG_ALIGN_NUM
#define LWMEM_CFG_ALIGN_NUM 4
#endif

/**
 * \brief           Enables `1` or disables `0` full memory management support.
 * 
 * When enabled (default config), library supports allocation, reallocation and freeing of the memory.
 *  - Memory [c]allocation
 *  - Memory reallocation
 *  - Memory allocation in user defined memory regions
 *  - Memory freeing
 * 
 * When disabled, library only supports allocation and does not provide any other service.
 *  - Its purpose is for memory allocation at the start of firmware initialization only
 * 
 * \note            When disabled, statistics functionaltiy is not available
 *                  and only one region is supported (for now, may be updated later).
 *                  API to allocate memory remains the same as for full configuration.
 */
#ifndef LWMEM_CFG_FULL
#define LWMEM_CFG_FULL 1
#endif

/**
 * \brief           Enables `1` or disables `0` memory cleanup on free operation (or realloc).
 *
 * It resets unused memory to `0x00` and prevents other applications seeing old data.
 * It is disabled by default since it has performance penalties.
 */
#ifndef LWMEM_CFG_CLEAN_MEMORY
#define LWMEM_CFG_CLEAN_MEMORY 0
#endif

/**
 * \brief           Enables `1` or disables `0` statistics in the library
 *
 */
#ifndef LWMEM_CFG_ENABLE_STATS
#define LWMEM_CFG_ENABLE_STATS 0
#endif

/**
 * \brief           Memory set function
 * 
 * \note            Function footprint is the same as \ref memset
 */
#ifndef LWMEM_MEMSET
#define LWMEM_MEMSET(dst, val, len) memset((dst), (val), (len))
#endif

/**
 * \brief           Memory copy function
 * 
 * \note            Function footprint is the same as \ref memcpy
 */
#ifndef LWMEM_MEMCPY
#define LWMEM_MEMCPY(dst, src, len) memcpy((dst), (src), (len))
#endif

/**
 * \brief           Memory move function
 * 
 * \note            Function footprint is the same as \ref memmove
 */
#ifndef LWMEM_MEMMOVE
#define LWMEM_MEMMOVE(dst, src, len) memmove((dst), (src), (len))
#endif

/**
 * \}
 */

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* LWMEM_OPT_HDR_H */
