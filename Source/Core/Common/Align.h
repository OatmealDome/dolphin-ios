// SPDX-License-Identifier: CC0-1.0

#pragma once

#include <cstddef>
#include <type_traits>

namespace Common
{

template <typename T>
constexpr T AlignDown(T value, size_t size)
{
  static_assert(std::is_unsigned<T>(), "T must be an unsigned value.");
  return static_cast<T>(value - value % size);
}

template <typename T>
constexpr T AlignUp(T value, size_t size)
{
  static_assert(std::is_unsigned<T>(), "T must be an unsigned value.");
  return AlignDown<T>(static_cast<T>(value + (size - 1)), size);
}

}  // namespace Common
