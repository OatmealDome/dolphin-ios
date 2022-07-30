// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include "InputCommon/ControllerInterface/iOS/MFiKeyboard.h"

#include "InputCommon/ControllerInterface/ControllerInterface.h"

namespace ciface::iOS
{
MFiKeyboard::MFiKeyboard(GCKeyboard* keyboard) : m_keyboard(keyboard)
{
  GCKeyboardInput* input = keyboard.keyboardInput;
  for (NSString* inputName in input.buttons)
  {
    if ([inputName isEqualToString:@""])
    {
      continue;
    }

    AddInput(new Key(input.buttons[inputName], std::string([inputName UTF8String])));
  }
}

std::string MFiKeyboard::GetName() const
{
  return "Keyboard";
}

std::string MFiKeyboard::GetSource() const
{
  return "MFi";
}

std::string MFiKeyboard::Key::GetName() const
{
  return m_name;
}

ControlState MFiKeyboard::Key::GetState() const
{
  return [m_input isPressed];
}
}  // namespace ciface::iOS
