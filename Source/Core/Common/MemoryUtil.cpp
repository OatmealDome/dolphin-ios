// Copyright 2008 Dolphin Emulator Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include "Common/MemoryUtil.h"

#include <cstddef>
#include <cstdlib>
#include <string>

#include "Common/CommonFuncs.h"
#include "Common/CommonTypes.h"
#include "Common/Logging/Log.h"
#include "Common/MsgHandler.h"

#ifdef _WIN32
#include <windows.h>
#include "Common/StringUtil.h"
#else
#include <pthread.h>
#include <stdio.h>
#include <sys/mman.h>
#include <sys/types.h>
#if defined __APPLE__ || defined __FreeBSD__ || defined __OpenBSD__ || defined __NetBSD__
#include <sys/sysctl.h>
#elif defined __HAIKU__
#include <OS.h>
#else
#include <sys/sysinfo.h>
#endif
#ifdef IPHONEOS
#include <lwmem/lwmem.h>
#include <mach/mach.h>
#include <unistd.h>
#endif
#endif

namespace Common
{
// This is purposely not a full wrapper for virtualalloc/mmap, but it
// provides exactly the primitive operations that Dolphin needs.

#ifndef IPHONEOS

void* AllocateExecutableMemory(size_t size)
{
#if defined(_WIN32)
  void* ptr = VirtualAlloc(nullptr, size, MEM_COMMIT, PAGE_EXECUTE_READWRITE);
#else
  int map_flags = MAP_ANON | MAP_PRIVATE;
#if defined(__APPLE__)
  map_flags |= MAP_JIT;
#endif

  int map_prot = PROT_READ | PROT_EXEC;
#ifndef IPHONEOS
  // The default protection is r-x on non-iOS platforms.
  map_prot |= PROT_WRITE;
#endif

  void* ptr = mmap(nullptr, size, map_prot, map_flags, -1, 0);
  if (ptr == MAP_FAILED)
    ptr = nullptr;
#endif

  if (ptr == nullptr)
    PanicAlertFmt("Failed to allocate executable memory: {}", LastStrerrorString());

  return ptr;
}

#else

// 512 MiB... hopefully this is enough, because we can't allocate more if we need it
constexpr size_t EXECUTABLE_REGION_SIZE = 536870912;

static u8* g_rx_region = nullptr;
static bool g_rx_region_prepared = false;
static ptrdiff_t g_rw_region_diff = 0;

void AllocateExecutableMemoryRegion()
{
  if (g_rx_region)
  {
    return;
  }

  const size_t size = EXECUTABLE_REGION_SIZE;
  u8* rx_ptr = static_cast<u8*>(mmap(nullptr, size, PROT_READ | PROT_EXEC, MAP_ANON | MAP_PRIVATE, -1, 0));

  if (!rx_ptr)
  {
    return;
  }

  vm_address_t rw_region;
  vm_address_t target = reinterpret_cast<vm_address_t>(rx_ptr);
  vm_prot_t cur_protection = 0;
  vm_prot_t max_protection = 0;

  kern_return_t retval =
      vm_remap(mach_task_self(), &rw_region, size, 0, true, mach_task_self(), target, false,
               &cur_protection, &max_protection, VM_INHERIT_DEFAULT);
  if (retval != KERN_SUCCESS)
  {
    return;
  }

  u8* rw_ptr = reinterpret_cast<u8*>(rw_region);

  if (mprotect(rw_ptr, size, PROT_READ | PROT_WRITE) != 0)
  {
    return;
  }

  lwmem_region_t regions[] =
  {
    { (void*)rw_ptr, size },
    { NULL, 0 }
  };

  size_t lwret = lwmem_assignmem(regions);
  if (lwret == 0)
  {
    return;
  }

  g_rx_region = rx_ptr;
  g_rw_region_diff = rw_ptr - rx_ptr;
}

void PrepareExecutableMemoryRegionOnTxmDevice()
{
  if (g_rx_region_prepared)
  {
    return;
  }

  const size_t size = EXECUTABLE_REGION_SIZE;

  asm ("mov x0, %0\n"
       "mov x1, %1\n"
       "brk #0x69" :: "r" (g_rx_region), "r" (size) : "x0", "x1");
  
  g_rx_region_prepared = true;
}

ptrdiff_t GetWritableRegionDiff()
{
  return g_rw_region_diff;
}

void* AllocateExecutableMemory(size_t size)
{
  if (g_rx_region == nullptr)
  {
    PanicAlertFmt("AllocateExecutableMemory failed!\ng_rx_region is nullptr");
    return nullptr;
  }

  const size_t pagesize = sysconf(_SC_PAGESIZE);

  void* raw = lwmem_malloc(size + pagesize - 1 + sizeof(void*));

  if (!raw)
  {
    PanicAlertFmt("AllocateExecutableMemory failed!\nlwmem_malloc returned nullptr");
    return nullptr;
  }

  uintptr_t raw_addr = (uintptr_t)raw + sizeof(void*);
  uintptr_t aligned = (raw_addr + pagesize - 1) & ~(pagesize - 1);

  ((void**)aligned)[-1] = raw;

  return (u8*)aligned - g_rw_region_diff;
}

void FreeExecutableMemory(void* ptr)
{
  lwmem_free(((void**)ptr)[-1]);
}

#endif

// This function is used to provide a counter for the JITPageWrite*Execute*
// functions to enable nesting. The static variable is wrapped in a a function
// to allow those functions to be called inside of the constructor of a static
// variable portably.
//
// The variable is thread_local as the W^X mode is specific to each running thread.
static int& JITPageWriteNestCounter()
{
  static thread_local int nest_counter = 0;
  return nest_counter;
}

// Certain platforms (Mac OS on ARM) enforce that a single thread can only have write or
// execute permissions to pages at any given point of time. The two below functions
// are used to toggle between having write permissions or execute permissions.
//
// The default state of these allocations in Dolphin is for them to be executable,
// but not writeable. So, functions that are updating these pages should wrap their
// writes like below:

// JITPageWriteEnableExecuteDisable();
// PrepareInstructionStreamForJIT();
// JITPageWriteDisableExecuteEnable();

// These functions can be nested, in which case execution will only be enabled
// after the call to the JITPageWriteDisableExecuteEnable from the top most
// nesting level. Example:

// [JIT page is in execute mode for the thread]
// JITPageWriteEnableExecuteDisable();
//   [JIT page is in write mode for the thread]
//   JITPageWriteEnableExecuteDisable();
//     [JIT page is in write mode for the thread]
//   JITPageWriteDisableExecuteEnable();
//   [JIT page is in write mode for the thread]
// JITPageWriteDisableExecuteEnable();
// [JIT page is in execute mode for the thread]

// Allows a thread to write to executable memory, but not execute the data.
void JITPageWriteEnableExecuteDisable()
{
#if defined(_M_ARM_64) && defined(__APPLE__) && !defined(IPHONEOS)
  if (JITPageWriteNestCounter() == 0)
  {
    pthread_jit_write_protect_np(0);
  }
#endif
  JITPageWriteNestCounter()++;
}
// Allows a thread to execute memory allocated for execution, but not write to it.
void JITPageWriteDisableExecuteEnable()
{
  JITPageWriteNestCounter()--;

  // Sanity check the NestCounter to identify underflow
  // This can indicate the calls to JITPageWriteDisableExecuteEnable()
  // are not matched with previous calls to JITPageWriteEnableExecuteDisable()
  if (JITPageWriteNestCounter() < 0)
    PanicAlertFmt("JITPageWriteNestCounter() underflowed");

#if defined(_M_ARM_64) && defined(__APPLE__) && !defined(IPHONEOS)
  if (JITPageWriteNestCounter() == 0)
  {
    pthread_jit_write_protect_np(1);
  }
#endif
}

void* AllocateMemoryPages(size_t size)
{
#ifdef _WIN32
  void* ptr = VirtualAlloc(nullptr, size, MEM_COMMIT, PAGE_READWRITE);
#else
  void* ptr = mmap(nullptr, size, PROT_READ | PROT_WRITE, MAP_ANON | MAP_PRIVATE, -1, 0);

  if (ptr == MAP_FAILED)
    ptr = nullptr;
#endif

  if (ptr == nullptr)
    PanicAlertFmt("Failed to allocate raw memory");

  return ptr;
}

void* AllocateAlignedMemory(size_t size, size_t alignment)
{
#ifdef _WIN32
  void* ptr = _aligned_malloc(size, alignment);
#else
  void* ptr = nullptr;
  if (posix_memalign(&ptr, alignment, size) != 0)
    ERROR_LOG_FMT(MEMMAP, "Failed to allocate aligned memory");
#endif

  if (ptr == nullptr)
    PanicAlertFmt("Failed to allocate aligned memory");

  return ptr;
}

bool FreeMemoryPages(void* ptr, size_t size)
{
  if (ptr)
  {
#ifdef _WIN32
    if (!VirtualFree(ptr, 0, MEM_RELEASE))
    {
      PanicAlertFmt("FreeMemoryPages failed!\nVirtualFree: {}", GetLastErrorString());
      return false;
    }
#else
    if (munmap(ptr, size) != 0)
    {
      PanicAlertFmt("FreeMemoryPages failed!\nmunmap: {}", LastStrerrorString());
      return false;
    }
#endif
  }
  return true;
}

void FreeAlignedMemory(void* ptr)
{
  if (ptr)
  {
#ifdef _WIN32
    _aligned_free(ptr);
#else
    free(ptr);
#endif
  }
}

bool ReadProtectMemory(void* ptr, size_t size)
{
#ifdef _WIN32
  DWORD oldValue;
  if (!VirtualProtect(ptr, size, PAGE_NOACCESS, &oldValue))
  {
    PanicAlertFmt("ReadProtectMemory failed!\nVirtualProtect: {}", GetLastErrorString());
    return false;
  }
#else
  if (mprotect(ptr, size, PROT_NONE) != 0)
  {
    PanicAlertFmt("ReadProtectMemory failed!\nmprotect: {}", LastStrerrorString());
    return false;
  }
#endif
  return true;
}

bool WriteProtectMemory(void* ptr, size_t size, bool allowExecute)
{
#ifdef _WIN32
  DWORD oldValue;
  if (!VirtualProtect(ptr, size, allowExecute ? PAGE_EXECUTE_READ : PAGE_READONLY, &oldValue))
  {
    PanicAlertFmt("WriteProtectMemory failed!\nVirtualProtect: {}", GetLastErrorString());
    return false;
  }
#elif !(defined(_M_ARM_64) && defined(__APPLE__) && !defined(IPHONEOS))
  // MacOS 11.2 on ARM does not allow for changing the access permissions of pages
  // that were marked executable, instead it uses the protections offered by MAP_JIT
  // for write protection.
  if (mprotect(ptr, size, allowExecute ? (PROT_READ | PROT_EXEC) : PROT_READ) != 0)
  {
    PanicAlertFmt("WriteProtectMemory failed!\nmprotect: {}", LastStrerrorString());
    return false;
  }
#endif
  return true;
}

bool UnWriteProtectMemory(void* ptr, size_t size, bool allowExecute)
{
#ifdef _WIN32
  DWORD oldValue;
  if (!VirtualProtect(ptr, size, allowExecute ? PAGE_EXECUTE_READWRITE : PAGE_READWRITE, &oldValue))
  {
    PanicAlertFmt("UnWriteProtectMemory failed!\nVirtualProtect: {}", GetLastErrorString());
    return false;
  }
#elif !(defined(_M_ARM_64) && defined(__APPLE__) && !defined(IPHONEOS))
  // MacOS 11.2 on ARM does not allow for changing the access permissions of pages
  // that were marked executable, instead it uses the protections offered by MAP_JIT
  // for write protection.
  if (mprotect(ptr, size,
               allowExecute ? (PROT_READ | PROT_WRITE | PROT_EXEC) : PROT_WRITE | PROT_READ) != 0)
  {
    PanicAlertFmt("UnWriteProtectMemory failed!\nmprotect: {}", LastStrerrorString());
    return false;
  }
#endif
  return true;
}

size_t MemPhysical()
{
#ifdef _WIN32
  MEMORYSTATUSEX memInfo;
  memInfo.dwLength = sizeof(MEMORYSTATUSEX);
  GlobalMemoryStatusEx(&memInfo);
  return memInfo.ullTotalPhys;
#elif defined __APPLE__ || defined __FreeBSD__ || defined __OpenBSD__ || defined __NetBSD__
  int mib[2];
  size_t physical_memory;
  mib[0] = CTL_HW;
#ifdef __APPLE__
  mib[1] = HW_MEMSIZE;
#elif defined __FreeBSD__
  mib[1] = HW_REALMEM;
#elif defined __OpenBSD__ || defined __NetBSD__
  mib[1] = HW_PHYSMEM64;
#endif
  size_t length = sizeof(size_t);
  sysctl(mib, 2, &physical_memory, &length, nullptr, 0);
  return physical_memory;
#elif defined __HAIKU__
  system_info sysinfo;
  get_system_info(&sysinfo);
  return static_cast<size_t>(sysinfo.max_pages * B_PAGE_SIZE);
#else
  struct sysinfo memInfo;
  sysinfo(&memInfo);
  return (size_t)memInfo.totalram * memInfo.mem_unit;
#endif
}

}  // namespace Common
