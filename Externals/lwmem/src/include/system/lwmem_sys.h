/**
 * \file            lwmem_sys.h
 * \brief           System functions for OS
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
#ifndef LWMEM_SYS_HDR_H
#define LWMEM_SYS_HDR_H

#include <stddef.h>
#include <stdint.h>
#include "lwmem/lwmem.h"

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

#if LWMEM_CFG_OS || __DOXYGEN__

/**
 * \defgroup        LWMEM_SYS System functions
 * \brief           System functions when used with operating system
 * \{
 */

/**
 * \brief           Create a new mutex and assign value to handle
 * \param[out]      m: Output variable to save mutex handle
 * \return          `1` on success, `0` otherwise
 */
uint8_t lwmem_sys_mutex_create(LWMEM_CFG_OS_MUTEX_HANDLE* m);

/**
 * \brief           Check if mutex handle is valid
 * \param[in]       m: Mutex handle to check if valid
 * \return          `1` on success, `0` otherwise
 */
uint8_t lwmem_sys_mutex_isvalid(LWMEM_CFG_OS_MUTEX_HANDLE* m);

/**
 * \brief           Wait for a mutex until ready (unlimited time)
 * \param[in]       m: Mutex handle to wait for
 * \return          `1` on success, `0` otherwise
 */
uint8_t lwmem_sys_mutex_wait(LWMEM_CFG_OS_MUTEX_HANDLE* m);

/**
 * \brief           Release already locked mutex
 * \param[in]       m: Mutex handle to release
 * \return          `1` on success, `0` otherwise
 */
uint8_t lwmem_sys_mutex_release(LWMEM_CFG_OS_MUTEX_HANDLE* m);

/**
 * \}
 */

#endif /* LWMEM_CFG_OS || __DOXYGEN__ */

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* LWMEM_SYS_HDR_H */
