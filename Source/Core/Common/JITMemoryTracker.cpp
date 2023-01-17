// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include "Common/JITMemoryTracker.h"

#include "Common/CommonTypes.h"
#include "Common/MemoryUtil.h"
#include "Common/MsgHandler.h"

namespace Common
{
JITMemoryTracker::JITMemoryTracker() = default;

void JITMemoryTracker::RegisterJITRegion(void* ptr, size_t size)
{
  std::scoped_lock lk(m_mutex);

  if (m_jit_regions.find(ptr) != m_jit_regions.end())
  {
    PanicAlertFmt("JITMemoryTracker: region {} already registered", ptr);
    return;
  }

  m_jit_regions[ptr] = {ptr, size, 0};
}

void JITMemoryTracker::UnregisterJITRegion(void* ptr)
{
  std::scoped_lock lk(m_mutex);

  m_jit_regions.erase(ptr);
}

JITMemoryTracker::JITRegionInfo* JITMemoryTracker::FindRegion(void* ptr)
{
  if (m_jit_regions.find(ptr) != m_jit_regions.end())
  {
    return &m_jit_regions[ptr];
  }

  for (auto& info : m_jit_regions)
  {
    void* region_end = static_cast<void*>(static_cast<u8*>(info.first) + info.second.size);
    if (ptr >= info.first && ptr <= region_end)
    {
      return &info.second;
    }
  }

  return nullptr;
}

void JITMemoryTracker::JITRegionWriteEnableExecuteDisable(void* ptr)
{
  std::scoped_lock lk(m_mutex);

  JITRegionInfo* info = FindRegion(ptr);

  if (!info)
  {
    return;
  }

  if (info->nest_counter == 0)
  {
    UnWriteProtectMemory(info->start_ptr, info->size, false);
  }

  info->nest_counter++;
}

void JITMemoryTracker::JITRegionWriteDisableExecuteEnable(void* ptr)
{
  std::scoped_lock lk(m_mutex);

  JITRegionInfo* info = FindRegion(ptr);

  if (!info)
  {
    return;
  }

  info->nest_counter--;

  if (info->nest_counter < 0)
  {
    PanicAlertFmt("JITMemoryTracker: Nest counter underflow for region {}", ptr);
  }
  else if (info->nest_counter == 0)
  {
    WriteProtectMemory(info->start_ptr, info->size, true);
  }
}
}  // namespace Common
