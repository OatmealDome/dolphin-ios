// Copyright 2008 Dolphin Emulator Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include "Common/MemoryUtil.h"

#include <lwmem/lwmem.h>
#include <mach/mach.h>
#include <stdio.h>
#include <string>
#include <sys/mman.h>
#include <sys/types.h>
#include <unistd.h>

#include "Common/CommonFuncs.h"
#include "Common/CommonTypes.h"
#include "Common/Logging/Log.h"
#include "Common/MsgHandler.h"

// 512 MiB... hopefully this is enough, because we can't allocate more if we need it
constexpr size_t EXECUTABLE_REGION_SIZE = 536870912;

static u8* g_rx_region = nullptr;
static ptrdiff_t g_rw_region_diff = 0;

namespace Common
{
void AllocateExecutableMemoryRegion_LuckTXM()
{
  if (g_rx_region)
  {
    return;
  }

  const size_t size = EXECUTABLE_REGION_SIZE;
  u8* rx_ptr = static_cast<u8*>(mmap(nullptr, size, PROT_READ | PROT_EXEC, MAP_ANON | MAP_PRIVATE, -1, 0));

  if (!rx_ptr)
  {
    PanicAlertFmt("AllocateExecutableMemoryRegion failed! mmap returned {}", LastStrerrorString());
    return;
  }

  asm ("mov x0, %0\n"
       "mov x1, %1\n"
       "brk #0x69" :: "r" (rx_ptr), "r" (size) : "x0", "x1");

  vm_address_t rw_region = 0;
  vm_address_t target = reinterpret_cast<vm_address_t>(rx_ptr);
  vm_prot_t cur_protection = 0;
  vm_prot_t max_protection = 0;

  kern_return_t retval =
      vm_remap(mach_task_self(), &rw_region, size, 0, true, mach_task_self(), target, false,
               &cur_protection, &max_protection, VM_INHERIT_DEFAULT);
  if (retval != KERN_SUCCESS)
  {
    PanicAlertFmt("AllocateExecutableMemoryRegion failed! vm_map returned {0:#x}", retval);
    return;
  }

  u8* rw_ptr = reinterpret_cast<u8*>(rw_region);

  if (mprotect(rw_ptr, size, PROT_READ | PROT_WRITE) != 0)
  {
    PanicAlertFmt("AllocateExecutableMemoryRegion failed! mprotect returned {}", LastStrerrorString());
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
    PanicAlertFmt("AllocateExecutableMemoryRegion failed!\nlwmem_assignmem failed");
    return;
  }

  g_rx_region = rx_ptr;
  g_rw_region_diff = rw_ptr - rx_ptr;
}

ptrdiff_t GetWritableRegionDiff_LuckTXM()
{
  return g_rw_region_diff;
}

void* AllocateExecutableMemory_LuckTXM(size_t size)
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

void FreeExecutableMemory_LuckTXM(void* ptr)
{
  lwmem_free(((void**)ptr)[-1]);
}
}  // namespace Common