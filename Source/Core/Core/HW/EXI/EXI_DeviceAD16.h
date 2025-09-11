// Copyright 2008 Dolphin Emulator Project
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include "Core/HW/EXI/EXI_Device.h"

class PointerWrap;

namespace ExpansionInterface
{
class CEXIAD16 : public IEXIDevice
{
public:
  explicit CEXIAD16(Core::System& system);
  void SetCS(int cs) override;
  bool IsPresent() const override;
  void DoState(PointerWrap& p) override;

private:
  enum
  {
    init = 0x00,
    write = 0xa0,
    read = 0xa2
  };

  union AD16Reg
  {
    u32 U32 = 0;
    u8 U8[4];
  };

  // STATE_TO_SAVE
  u32 m_position = 0;
  u32 m_command = 0;
  AD16Reg m_ad16_register;

  void TransferByte(u8& byte) override;
};
}  // namespace ExpansionInterface
