// Copyright 2025 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include "Common/MemoryUtil.h"

#include <stdio.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <unistd.h>

#include "Common/CommonFuncs.h"
#include "Common/CommonTypes.h"
#include "Common/JITMemoryTracker.h"
#include "Common/Logging/Log.h"
#include "Common/MsgHandler.h"

namespace Common
{
static JITMemoryTracker g_jit_memory_tracker;

void* AllocateExecutableMemory_Legacy(size_t size)
{
  void* ptr = mmap(nullptr, size, PROT_READ | PROT_EXEC, MAP_ANON | MAP_PRIVATE, -1, 0);
  if (ptr == MAP_FAILED)
  {
    ptr = nullptr;
  }

  if (ptr == nullptr)
  {
    PanicAlertFmt("Failed to allocate executable memory: {}", LastStrerrorString());
  }

  g_jit_memory_tracker.RegisterJITRegion(ptr, size);

  return ptr;
}

void FreeExecutableMemory_Legacy(void* ptr, size_t size)
{
  if (ptr)
  {
    if (munmap(ptr, size) != 0)
    {
      PanicAlertFmt("FreeExecutableMemory failed!\nmunmap: {}", LastStrerrorString());
    }

    g_jit_memory_tracker.UnregisterJITRegion(ptr);
  }
}

void JITPageWriteEnableExecuteDisable_Legacy(void* ptr)
{
  g_jit_memory_tracker.JITRegionWriteEnableExecuteDisable(ptr);
}

void JITPageWriteDisableExecuteEnable_Legacy(void* ptr)
{
  g_jit_memory_tracker.JITRegionWriteDisableExecuteEnable(ptr);
}
}  // namespace Common
