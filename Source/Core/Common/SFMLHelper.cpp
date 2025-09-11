// Copyright 2018 Dolphin Emulator Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include "Common/SFMLHelper.h"

#include <SFML/Network/Packet.hpp>

sf::Packet& operator>>(sf::Packet& packet, Common::BigEndianValue<u16>& data)
{
  u16 tmp;
  packet >> tmp;
  data = tmp;
  return packet;
}

sf::Packet& operator>>(sf::Packet& packet, Common::BigEndianValue<u32>& data)
{
  u32 tmp;
  packet >> tmp;
  data = tmp;
  return packet;
}

sf::Packet& operator>>(sf::Packet& packet, Common::BigEndianValue<u64>& data)
{
  u64 tmp;
  packet >> tmp;
  data = tmp;
  return packet;
}

namespace Common
{
// SFML's Uint64 type is different depending on platform,
// so we have this for cleaner code.
u64 PacketReadU64(sf::Packet& packet)
{
  u64 value;
  packet >> value;
  return value;
}
}  // namespace Common
