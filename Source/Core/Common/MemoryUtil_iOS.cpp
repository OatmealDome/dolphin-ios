// Copyright 2008 Dolphin Emulator Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include "Common/MemoryUtil.h"

#include "Common/CommonTypes.h"
#include "Common/MsgHandler.h"

namespace Common
{
static JitType g_jit_type = JitType::LuckTXM;

void SetJitType(JitType type)
{
  g_jit_type = type;
}

void* AllocateExecutableMemory(size_t size)
{
  if (g_jit_type == JitType::LuckTXM)
  {
    return AllocateExecutableMemory_LuckTXM(size);
  }

  PanicAlertFmt("AllocateExecutableMemory failed!\nUnknown JIT type set");
  return nullptr;
}

void FreeExecutableMemory(void* ptr)
{
  if (g_jit_type == JitType::LuckTXM)
  {
    FreeExecutableMemory_LuckTXM(ptr);
  }
}

void AllocateExecutableMemoryRegion()
{
  if (g_jit_type == JitType::LuckTXM)
  {
    AllocateExecutableMemoryRegion_LuckTXM();
  }
}

ptrdiff_t GetWritableRegionDiff()
{
  if (g_jit_type == JitType::LuckTXM)
  {
    return GetWritableRegionDiff_LuckTXM();
  }

  return 0;
}
}  // namespace Common