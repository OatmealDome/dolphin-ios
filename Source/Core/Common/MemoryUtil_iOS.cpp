// Copyright 2008 Dolphin Emulator Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include "Common/MemoryUtil.h"

#include "Common/CommonTypes.h"

namespace Common
{
void* AllocateExecutableMemory(size_t size)
{
  return AllocateExecutableMemory_LuckTXM(size);
}

void FreeExecutableMemory(void* ptr)
{
  FreeExecutableMemory_LuckTXM(ptr);
}

void AllocateExecutableMemoryRegion()
{
  AllocateExecutableMemoryRegion_LuckTXM();
}

void PrepareExecutableMemoryRegionOnTxmDevice()
{
  PrepareExecutableMemoryRegionOnTxmDevice_LuckTXM();
}

ptrdiff_t GetWritableRegionDiff()
{
  return GetWritableRegionDiff_LuckTXM();
}
}  // namespace Common