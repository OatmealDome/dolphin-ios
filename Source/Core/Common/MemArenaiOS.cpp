// Copyright 2008 Dolphin Emulator Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include "Common/MemArena.h"

#include "Common/Assert.h"
#include "Common/Logging/Log.h"

namespace Common
{
MemArena::MemArena() = default;
MemArena::~MemArena() = default;

void MemArena::GrabSHMSegment(size_t size, std::string_view base_name)
{
  kern_return_t retval = vm_allocate(mach_task_self(), &m_shm_address, size, VM_FLAGS_ANYWHERE);
  if (retval != KERN_SUCCESS)
  {
    m_shm_address = 0;
    ERROR_LOG_FMT(MEMMAP, "Failed to allocate low memory space: {0:#x}", retval);
  }

  m_shm_size = size;
}

void MemArena::ReleaseSHMSegment()
{
  if (m_shm_address != 0)
  {
    vm_deallocate(mach_task_self(), m_shm_address, m_shm_size);
  }

  m_shm_address = 0;
  m_shm_size = 0;
}

void* MemArena::CreateView(s64 offset, size_t size)
{
  if (m_shm_address == 0)
  {
    ERROR_LOG_FMT(MEMMAP, "CreateView failed: no shared memory segment allocated");
    return nullptr;
  }

  vm_address_t target = 0;
  uint64_t mask = 0;
  vm_address_t source = m_shm_address + offset;
  vm_prot_t cur_protection = 0;
  vm_prot_t max_protection = 0;

  kern_return_t retval =
      vm_remap(mach_task_self(), &target, size, mask, true, mach_task_self(), source, false,
               &cur_protection, &max_protection, VM_INHERIT_DEFAULT);
  if (retval != KERN_SUCCESS)
  {
    ERROR_LOG_FMT(MEMMAP, "vm_remap failed {0:#x}", retval);
    return nullptr;
  }

  return reinterpret_cast<void*>(target);
}

void MemArena::ReleaseView(void* view, size_t size)
{
  if (m_shm_address == 0)
  {
    ERROR_LOG_FMT(MEMMAP, "ReleaseView failed: no shared memory segment allocated");
    return;
  }

  vm_deallocate(mach_task_self(), reinterpret_cast<vm_address_t>(view), size);
}

u8* MemArena::ReserveMemoryRegion(size_t memory_size)
{
  vm_address_t addr = 0;
  kern_return_t retval = vm_allocate(mach_task_self(), &addr, memory_size, VM_FLAGS_ANYWHERE);
  if (retval != KERN_SUCCESS)
  {
    ERROR_LOG_FMT(MEMMAP, "vm_allocate failed: {0:#x}", retval);
    return nullptr;
  }

  vm_deallocate(mach_task_self(), addr, memory_size);

  return reinterpret_cast<u8*>(addr);
}

void MemArena::ReleaseMemoryRegion()
{
}

void* MemArena::MapInMemoryRegion(s64 offset, size_t size, void* base)
{
  if (m_shm_address == 0)
  {
    ERROR_LOG_FMT(MEMMAP, "MapInMemoryRegion failed: no shared memory segment allocated");
    return nullptr;
  }

  vm_address_t target = reinterpret_cast<vm_address_t>(base);
  uint64_t mask = 0;
  vm_address_t source = m_shm_address + offset;
  vm_prot_t cur_protection = 0;
  vm_prot_t max_protection = 0;

  kern_return_t retval =
      vm_remap(mach_task_self(), &target, size, mask, false, mach_task_self(), source, false,
               &cur_protection, &max_protection, VM_INHERIT_DEFAULT);
  if (retval != KERN_SUCCESS)
  {
    ERROR_LOG_FMT(MEMMAP, "vm_remap failed: {0:#x}", retval);
    return nullptr;
  }

  return reinterpret_cast<void*>(target);
}

void MemArena::UnmapFromMemoryRegion(void* view, size_t size)
{
  if (m_shm_address == 0)
  {
    ERROR_LOG_FMT(MEMMAP, "UnmapFromMemoryRegion failed: no shared memory segment allocated");
    return;
  }

  vm_deallocate(mach_task_self(), reinterpret_cast<vm_address_t>(view), size);
}

LazyMemoryRegion::LazyMemoryRegion() = default;

LazyMemoryRegion::~LazyMemoryRegion()
{
  Release();
}

void* LazyMemoryRegion::Create(size_t size)
{
  ASSERT(!m_memory);

  if (size == 0)
    return nullptr;

  vm_address_t memory = 0;

  kern_return_t retval = vm_allocate(mach_task_self(), &memory, size, VM_FLAGS_ANYWHERE);
  if (retval != KERN_SUCCESS)
  {
    m_memory = 0;
    ERROR_LOG_FMT(MEMMAP, "Failed to allocate memory space: {0:#x}", retval);
  }

  m_memory = reinterpret_cast<void*>(memory);
  m_size = size;

  return m_memory;
}

void LazyMemoryRegion::Clear()
{
  ASSERT(m_memory);

  memset(m_memory, 0, m_size);
}

void LazyMemoryRegion::Release()
{
  if (m_memory)
  {
    vm_deallocate(mach_task_self(), reinterpret_cast<vm_address_t>(m_memory), m_size);

    m_memory = nullptr;
    m_size = 0;
  }
}
}  // namespace Common
