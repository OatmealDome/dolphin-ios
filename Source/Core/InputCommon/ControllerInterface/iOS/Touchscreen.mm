// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include "InputCommon/ControllerInterface/iOS/Touchscreen.h"

#include <CoreHaptics/CoreHaptics.h>
#include <Foundation/Foundation.h>
#include <sstream>

#include "Common/Logging/Log.h"

#include "InputCommon/ControllerInterface/ControllerInterface.h"
#include "InputCommon/ControllerInterface/iOS/Motor.h"
#include "InputCommon/ControllerInterface/iOS/StateManager.h"

namespace ciface::iOS
{
std::string Touchscreen::GetName() const
{
  return "Touchscreen";
}

std::string Touchscreen::GetSource() const
{
  return "iOS";
}

Touchscreen::Touchscreen(int controller_id, bool wiimote)
    : m_controller_id(controller_id)
{
  if (!wiimote)
  {
    // GC
    AddInput(new Button(m_controller_id, ButtonType::BUTTON_A));
    AddInput(new Button(m_controller_id, ButtonType::BUTTON_B));
    AddInput(new Button(m_controller_id, ButtonType::BUTTON_START));
    AddInput(new Button(m_controller_id, ButtonType::BUTTON_X));
    AddInput(new Button(m_controller_id, ButtonType::BUTTON_Y));
    AddInput(new Button(m_controller_id, ButtonType::BUTTON_Z));
    AddInput(new Button(m_controller_id, ButtonType::BUTTON_UP));
    AddInput(new Button(m_controller_id, ButtonType::BUTTON_DOWN));
    AddInput(new Button(m_controller_id, ButtonType::BUTTON_LEFT));
    AddInput(new Button(m_controller_id, ButtonType::BUTTON_RIGHT));
    AddInput(new Axis(m_controller_id, ButtonType::STICK_MAIN_LEFT, -1.0f));
    AddInput(new Axis(m_controller_id, ButtonType::STICK_MAIN_RIGHT));
    AddInput(new Axis(m_controller_id, ButtonType::STICK_MAIN_UP, -1.0f));
    AddInput(new Axis(m_controller_id, ButtonType::STICK_MAIN_DOWN));
    AddInput(new Axis(m_controller_id, ButtonType::STICK_C_LEFT, -1.0f));
    AddInput(new Axis(m_controller_id, ButtonType::STICK_C_RIGHT));
    AddInput(new Axis(m_controller_id, ButtonType::STICK_C_UP, -1.0f));
    AddInput(new Axis(m_controller_id, ButtonType::STICK_C_DOWN));
    AddInput(new Axis(m_controller_id, ButtonType::TRIGGER_L));
    AddInput(new Axis(m_controller_id, ButtonType::TRIGGER_R));
  }
  else
  {
    // Wiimote
    AddInput(new Button(m_controller_id, ButtonType::WIIMOTE_BUTTON_A));
    AddInput(new Button(m_controller_id, ButtonType::WIIMOTE_BUTTON_B));
    AddInput(new Button(m_controller_id, ButtonType::WIIMOTE_BUTTON_MINUS));
    AddInput(new Button(m_controller_id, ButtonType::WIIMOTE_BUTTON_PLUS));
    AddInput(new Button(m_controller_id, ButtonType::WIIMOTE_BUTTON_HOME));
    AddInput(new Button(m_controller_id, ButtonType::WIIMOTE_BUTTON_1));
    AddInput(new Button(m_controller_id, ButtonType::WIIMOTE_BUTTON_2));
    AddInput(new Button(m_controller_id, ButtonType::WIIMOTE_UP));
    AddInput(new Button(m_controller_id, ButtonType::WIIMOTE_DOWN));
    AddInput(new Button(m_controller_id, ButtonType::WIIMOTE_LEFT));
    AddInput(new Button(m_controller_id, ButtonType::WIIMOTE_RIGHT));
    AddInput(new Button(m_controller_id, ButtonType::WIIMOTE_IR_HIDE));
    AddInput(new Button(m_controller_id, ButtonType::WIIMOTE_TILT_MODIFIER));
    AddInput(new Button(m_controller_id, ButtonType::WIIMOTE_SHAKE_X));
    AddInput(new Button(m_controller_id, ButtonType::WIIMOTE_SHAKE_Y));
    AddInput(new Button(m_controller_id, ButtonType::WIIMOTE_SHAKE_Z));
    AddInput(new Axis(m_controller_id, ButtonType::WIIMOTE_IR_UP, -1.0f));
    AddInput(new Axis(m_controller_id, ButtonType::WIIMOTE_IR_DOWN));
    AddInput(new Axis(m_controller_id, ButtonType::WIIMOTE_IR_LEFT, -1.0f));
    AddInput(new Axis(m_controller_id, ButtonType::WIIMOTE_IR_RIGHT));
    AddInput(new Axis(m_controller_id, ButtonType::WIIMOTE_IR_FORWARD, -1.0f));
    AddInput(new Axis(m_controller_id, ButtonType::WIIMOTE_IR_BACKWARD));
    AddInput(new Axis(m_controller_id, ButtonType::WIIMOTE_SWING_UP, -1.0f));
    AddInput(new Axis(m_controller_id, ButtonType::WIIMOTE_SWING_DOWN));
    AddInput(new Axis(m_controller_id, ButtonType::WIIMOTE_SWING_LEFT, -1.0f));
    AddInput(new Axis(m_controller_id, ButtonType::WIIMOTE_SWING_RIGHT));
    AddInput(new Axis(m_controller_id, ButtonType::WIIMOTE_SWING_FORWARD, -1.0f));
    AddInput(new Axis(m_controller_id, ButtonType::WIIMOTE_SWING_BACKWARD));
    AddInput(new Axis(m_controller_id, ButtonType::WIIMOTE_TILT_LEFT, -1.0f));
    AddInput(new Axis(m_controller_id, ButtonType::WIIMOTE_TILT_RIGHT));
    AddInput(new Axis(m_controller_id, ButtonType::WIIMOTE_TILT_FORWARD, -1.0f));
    AddInput(new Axis(m_controller_id, ButtonType::WIIMOTE_TILT_BACKWARD));

    // Nunchuk
    AddInput(new Button(m_controller_id, ButtonType::NUNCHUK_BUTTON_C));
    AddInput(new Button(m_controller_id, ButtonType::NUNCHUK_BUTTON_Z));
    AddInput(new Button(m_controller_id, ButtonType::NUNCHUK_TILT_MODIFIER));
    AddInput(new Button(m_controller_id, ButtonType::NUNCHUK_SHAKE_X));
    AddInput(new Button(m_controller_id, ButtonType::NUNCHUK_SHAKE_Y));
    AddInput(new Button(m_controller_id, ButtonType::NUNCHUK_SHAKE_Z));
    AddInput(new Axis(m_controller_id, ButtonType::NUNCHUK_STICK_LEFT, -1.0f));
    AddInput(new Axis(m_controller_id, ButtonType::NUNCHUK_STICK_RIGHT));
    AddInput(new Axis(m_controller_id, ButtonType::NUNCHUK_STICK_UP, -1.0f));
    AddInput(new Axis(m_controller_id, ButtonType::NUNCHUK_STICK_DOWN));
    AddInput(new Axis(m_controller_id, ButtonType::NUNCHUK_SWING_LEFT, -1.0f));
    AddInput(new Axis(m_controller_id, ButtonType::NUNCHUK_SWING_RIGHT));
    AddInput(new Axis(m_controller_id, ButtonType::NUNCHUK_SWING_UP, -1.0f));
    AddInput(new Axis(m_controller_id, ButtonType::NUNCHUK_SWING_DOWN));
    AddInput(new Axis(m_controller_id, ButtonType::NUNCHUK_SWING_FORWARD, -1.0f));
    AddInput(new Axis(m_controller_id, ButtonType::NUNCHUK_SWING_BACKWARD));
    AddInput(new Axis(m_controller_id, ButtonType::NUNCHUK_TILT_LEFT, -1.0f));
    AddInput(new Axis(m_controller_id, ButtonType::NUNCHUK_TILT_RIGHT));
    AddInput(new Axis(m_controller_id, ButtonType::NUNCHUK_TILT_FORWARD, -1.0f));
    AddInput(new Axis(m_controller_id, ButtonType::NUNCHUK_TILT_BACKWARD));

    // Classic Controller
    AddInput(new Button(m_controller_id, ButtonType::CLASSIC_BUTTON_A));
    AddInput(new Button(m_controller_id, ButtonType::CLASSIC_BUTTON_B));
    AddInput(new Button(m_controller_id, ButtonType::CLASSIC_BUTTON_X));
    AddInput(new Button(m_controller_id, ButtonType::CLASSIC_BUTTON_Y));
    AddInput(new Button(m_controller_id, ButtonType::CLASSIC_BUTTON_MINUS));
    AddInput(new Button(m_controller_id, ButtonType::CLASSIC_BUTTON_PLUS));
    AddInput(new Button(m_controller_id, ButtonType::CLASSIC_BUTTON_HOME));
    AddInput(new Button(m_controller_id, ButtonType::CLASSIC_BUTTON_ZL));
    AddInput(new Button(m_controller_id, ButtonType::CLASSIC_BUTTON_ZR));
    AddInput(new Button(m_controller_id, ButtonType::CLASSIC_DPAD_UP));
    AddInput(new Button(m_controller_id, ButtonType::CLASSIC_DPAD_DOWN));
    AddInput(new Button(m_controller_id, ButtonType::CLASSIC_DPAD_LEFT));
    AddInput(new Button(m_controller_id, ButtonType::CLASSIC_DPAD_RIGHT));
    AddInput(new Axis(m_controller_id, ButtonType::CLASSIC_STICK_LEFT_LEFT, -1.0f));
    AddInput(new Axis(m_controller_id, ButtonType::CLASSIC_STICK_LEFT_RIGHT));
    AddInput(new Axis(m_controller_id, ButtonType::CLASSIC_STICK_LEFT_UP, -1.0f));
    AddInput(new Axis(m_controller_id, ButtonType::CLASSIC_STICK_LEFT_DOWN));
    AddInput(new Axis(m_controller_id, ButtonType::CLASSIC_STICK_RIGHT_LEFT, -1.0f));
    AddInput(new Axis(m_controller_id, ButtonType::CLASSIC_STICK_RIGHT_RIGHT));
    AddInput(new Axis(m_controller_id, ButtonType::CLASSIC_STICK_RIGHT_UP, -1.0f));
    AddInput(new Axis(m_controller_id, ButtonType::CLASSIC_STICK_RIGHT_DOWN));
    AddInput(new Axis(m_controller_id, ButtonType::CLASSIC_TRIGGER_L));
    AddInput(new Axis(m_controller_id, ButtonType::CLASSIC_TRIGGER_R));

    // Wiimote IMU
    AddInput(new Axis(m_controller_id, ButtonType::WIIMOTE_ACCEL_LEFT));
    AddInput(new Axis(m_controller_id, ButtonType::WIIMOTE_ACCEL_RIGHT, -1.0f));
    AddInput(new Axis(m_controller_id, ButtonType::WIIMOTE_ACCEL_FORWARD, -1.0f));
    AddInput(new Axis(m_controller_id, ButtonType::WIIMOTE_ACCEL_BACKWARD));
    AddInput(new Axis(m_controller_id, ButtonType::WIIMOTE_ACCEL_UP));
    AddInput(new Axis(m_controller_id, ButtonType::WIIMOTE_ACCEL_DOWN, -1.0f));
    AddInput(new Axis(m_controller_id, ButtonType::WIIMOTE_GYRO_PITCH_UP, -1.0f));
    AddInput(new Axis(m_controller_id, ButtonType::WIIMOTE_GYRO_PITCH_DOWN));
    AddInput(new Axis(m_controller_id, ButtonType::WIIMOTE_GYRO_ROLL_LEFT));
    AddInput(new Axis(m_controller_id, ButtonType::WIIMOTE_GYRO_ROLL_RIGHT, -1.0f));
    AddInput(new Axis(m_controller_id, ButtonType::WIIMOTE_GYRO_YAW_LEFT));
    AddInput(new Axis(m_controller_id, ButtonType::WIIMOTE_GYRO_YAW_RIGHT, -1.0f));
    
    // Nunchuk IMU
    AddInput(new Axis(m_controller_id, ButtonType::NUNCHUK_ACCEL_LEFT));
    AddInput(new Axis(m_controller_id, ButtonType::NUNCHUK_ACCEL_RIGHT, -1.0f));
    AddInput(new Axis(m_controller_id, ButtonType::NUNCHUK_ACCEL_FORWARD, -1.0f));
    AddInput(new Axis(m_controller_id, ButtonType::NUNCHUK_ACCEL_BACKWARD));
    AddInput(new Axis(m_controller_id, ButtonType::NUNCHUK_ACCEL_UP));
    AddInput(new Axis(m_controller_id, ButtonType::NUNCHUK_ACCEL_DOWN, -1.0f));
  }

  // Rumble
  if ([[CHHapticEngine capabilitiesForHardware] supportsHaptics])
  {
    std::ostringstream ss;
    ss << "Rumble " << static_cast<int>(ButtonType::RUMBLE);

    NSError* error;
    CHHapticEngine* engine = [[CHHapticEngine alloc] initAndReturnError:&error];

    if (error != nil)
    {
      ERROR_LOG_FMT(SERIALINTERFACE, "Touchscreen failed to create CHHapticEngine: {}",
                    [[error localizedDescription] UTF8String]);
      return;
    }

    AddOutput(new Motor(engine, ss.str()));
  }
}

std::string Touchscreen::Button::GetName() const
{
  std::ostringstream ss;
  ss << "Button " << static_cast<int>(m_index);
  return ss.str();
}

ControlState Touchscreen::Button::GetState() const
{
  bool result = StateManager::GetInstance()->GetButtonPressed(m_controller_id, m_index);
  return result ? 1.0 : 0.0;
}

std::string Touchscreen::Axis::GetName() const
{
  std::ostringstream ss;
  ss << "Axis " << static_cast<int>(m_index);
  return ss.str();
}

ControlState Touchscreen::Axis::GetState() const
{
  return StateManager::GetInstance()->GetAxisValue(m_controller_id, m_index) * m_neg;
}
}  // namespace ciface::iOS
