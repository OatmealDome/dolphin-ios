// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include "InputCommon/ControllerInterface/iOS/StateManager.h"

#include <vector>

namespace ciface::iOS
{
StateManager StateManager::s_instance;

void StateManager::ControllerState::PopulateButton(ButtonType button)
{
  m_buttons[button] = false;
}

void StateManager::ControllerState::PopulateAxis(ButtonType axis)
{
  m_axes[axis] = 0.0f;
}

StateManager::StateManager()
{
    // Populate with GameCube controllers
  for (int i = 0; i < 4; i++)
  {
    ControllerState state;

    state.PopulateButton(ButtonType::BUTTON_A);
    state.PopulateButton(ButtonType::BUTTON_B);
    state.PopulateButton(ButtonType::BUTTON_START);
    state.PopulateButton(ButtonType::BUTTON_X);
    state.PopulateButton(ButtonType::BUTTON_Y);
    state.PopulateButton(ButtonType::BUTTON_Z);
    state.PopulateButton(ButtonType::BUTTON_UP);
    state.PopulateButton(ButtonType::BUTTON_DOWN);
    state.PopulateButton(ButtonType::BUTTON_LEFT);
    state.PopulateButton(ButtonType::BUTTON_RIGHT);
    state.PopulateAxis(ButtonType::STICK_MAIN_UP);
    state.PopulateAxis(ButtonType::STICK_MAIN_DOWN);
    state.PopulateAxis(ButtonType::STICK_MAIN_LEFT);
    state.PopulateAxis(ButtonType::STICK_MAIN_RIGHT);
    state.PopulateAxis(ButtonType::STICK_C_UP);
    state.PopulateAxis(ButtonType::STICK_C_DOWN);
    state.PopulateAxis(ButtonType::STICK_C_LEFT);
    state.PopulateAxis(ButtonType::STICK_C_RIGHT);
    state.PopulateAxis(ButtonType::TRIGGER_L);
    state.PopulateAxis(ButtonType::TRIGGER_R);

    m_controllers.push_back(state);
  }

  for (int i = 0; i < 4; i++)
  {
    ControllerState state;

    // Wiimote
    state.PopulateButton(ButtonType::WIIMOTE_BUTTON_A);
    state.PopulateButton(ButtonType::WIIMOTE_BUTTON_B);
    state.PopulateButton(ButtonType::WIIMOTE_BUTTON_MINUS);
    state.PopulateButton(ButtonType::WIIMOTE_BUTTON_PLUS);
    state.PopulateButton(ButtonType::WIIMOTE_BUTTON_HOME);
    state.PopulateButton(ButtonType::WIIMOTE_BUTTON_1);
    state.PopulateButton(ButtonType::WIIMOTE_BUTTON_2);
    state.PopulateButton(ButtonType::WIIMOTE_UP);
    state.PopulateButton(ButtonType::WIIMOTE_DOWN);
    state.PopulateButton(ButtonType::WIIMOTE_LEFT);
    state.PopulateButton(ButtonType::WIIMOTE_RIGHT);
    state.PopulateAxis(ButtonType::WIIMOTE_IR_UP);
    state.PopulateAxis(ButtonType::WIIMOTE_IR_DOWN);
    state.PopulateAxis(ButtonType::WIIMOTE_IR_LEFT);
    state.PopulateAxis(ButtonType::WIIMOTE_IR_RIGHT);
    state.PopulateAxis(ButtonType::WIIMOTE_IR_FORWARD);
    state.PopulateAxis(ButtonType::WIIMOTE_IR_BACKWARD);
    state.PopulateButton(ButtonType::WIIMOTE_IR_HIDE);
    state.PopulateAxis(ButtonType::WIIMOTE_SWING_UP);
    state.PopulateAxis(ButtonType::WIIMOTE_SWING_DOWN);
    state.PopulateAxis(ButtonType::WIIMOTE_SWING_LEFT);
    state.PopulateAxis(ButtonType::WIIMOTE_SWING_RIGHT);
    state.PopulateAxis(ButtonType::WIIMOTE_SWING_FORWARD);
    state.PopulateAxis(ButtonType::WIIMOTE_SWING_BACKWARD);
    state.PopulateAxis(ButtonType::WIIMOTE_TILT_FORWARD);
    state.PopulateAxis(ButtonType::WIIMOTE_TILT_BACKWARD);
    state.PopulateAxis(ButtonType::WIIMOTE_TILT_LEFT);
    state.PopulateAxis(ButtonType::WIIMOTE_TILT_RIGHT);
    state.PopulateButton(ButtonType::WIIMOTE_TILT_MODIFIER);
    state.PopulateButton(ButtonType::WIIMOTE_SHAKE_X);
    state.PopulateButton(ButtonType::WIIMOTE_SHAKE_Y);
    state.PopulateButton(ButtonType::WIIMOTE_SHAKE_Z);

    // Nunchuk
    state.PopulateButton(ButtonType::NUNCHUK_BUTTON_C);
    state.PopulateButton(ButtonType::NUNCHUK_BUTTON_Z);
    state.PopulateAxis(ButtonType::NUNCHUK_STICK_UP);
    state.PopulateAxis(ButtonType::NUNCHUK_STICK_DOWN);
    state.PopulateAxis(ButtonType::NUNCHUK_STICK_LEFT);
    state.PopulateAxis(ButtonType::NUNCHUK_STICK_RIGHT);
    state.PopulateAxis(ButtonType::NUNCHUK_SWING_UP);
    state.PopulateAxis(ButtonType::NUNCHUK_SWING_DOWN);
    state.PopulateAxis(ButtonType::NUNCHUK_SWING_LEFT);
    state.PopulateAxis(ButtonType::NUNCHUK_SWING_RIGHT);
    state.PopulateAxis(ButtonType::NUNCHUK_SWING_FORWARD);
    state.PopulateAxis(ButtonType::NUNCHUK_SWING_BACKWARD);
    state.PopulateAxis(ButtonType::NUNCHUK_TILT_FORWARD);
    state.PopulateAxis(ButtonType::NUNCHUK_TILT_BACKWARD);
    state.PopulateAxis(ButtonType::NUNCHUK_TILT_LEFT);
    state.PopulateAxis(ButtonType::NUNCHUK_TILT_RIGHT);
    state.PopulateButton(ButtonType::NUNCHUK_TILT_MODIFIER);
    state.PopulateButton(ButtonType::NUNCHUK_SHAKE_X);
    state.PopulateButton(ButtonType::NUNCHUK_SHAKE_Y);
    state.PopulateButton(ButtonType::NUNCHUK_SHAKE_Z);

    // Classic Controller
    state.PopulateButton(ButtonType::CLASSIC_BUTTON_A);
    state.PopulateButton(ButtonType::CLASSIC_BUTTON_B);
    state.PopulateButton(ButtonType::CLASSIC_BUTTON_X);
    state.PopulateButton(ButtonType::CLASSIC_BUTTON_Y);
    state.PopulateButton(ButtonType::CLASSIC_BUTTON_MINUS);
    state.PopulateButton(ButtonType::CLASSIC_BUTTON_PLUS);
    state.PopulateButton(ButtonType::CLASSIC_BUTTON_HOME);
    state.PopulateButton(ButtonType::CLASSIC_BUTTON_ZL);
    state.PopulateButton(ButtonType::CLASSIC_BUTTON_ZR);
    state.PopulateButton(ButtonType::CLASSIC_DPAD_UP);
    state.PopulateButton(ButtonType::CLASSIC_DPAD_DOWN);
    state.PopulateButton(ButtonType::CLASSIC_DPAD_LEFT);
    state.PopulateButton(ButtonType::CLASSIC_DPAD_RIGHT);
    state.PopulateAxis(ButtonType::CLASSIC_STICK_LEFT_UP);
    state.PopulateAxis(ButtonType::CLASSIC_STICK_LEFT_DOWN);
    state.PopulateAxis(ButtonType::CLASSIC_STICK_LEFT_LEFT);
    state.PopulateAxis(ButtonType::CLASSIC_STICK_LEFT_RIGHT);
    state.PopulateAxis(ButtonType::CLASSIC_STICK_RIGHT_UP);
    state.PopulateAxis(ButtonType::CLASSIC_STICK_RIGHT_DOWN);
    state.PopulateAxis(ButtonType::CLASSIC_STICK_RIGHT_LEFT);
    state.PopulateAxis(ButtonType::CLASSIC_STICK_RIGHT_RIGHT);
    state.PopulateAxis(ButtonType::CLASSIC_TRIGGER_L);
    state.PopulateAxis(ButtonType::CLASSIC_TRIGGER_R);

    // IMU
    state.PopulateAxis(ButtonType::WIIMOTE_ACCEL_LEFT);
    state.PopulateAxis(ButtonType::WIIMOTE_ACCEL_RIGHT);
    state.PopulateAxis(ButtonType::WIIMOTE_ACCEL_FORWARD);
    state.PopulateAxis(ButtonType::WIIMOTE_ACCEL_BACKWARD);
    state.PopulateAxis(ButtonType::WIIMOTE_ACCEL_UP);
    state.PopulateAxis(ButtonType::WIIMOTE_ACCEL_DOWN);
    state.PopulateAxis(ButtonType::WIIMOTE_GYRO_PITCH_UP);
    state.PopulateAxis(ButtonType::WIIMOTE_GYRO_PITCH_DOWN);
    state.PopulateAxis(ButtonType::WIIMOTE_GYRO_ROLL_LEFT);
    state.PopulateAxis(ButtonType::WIIMOTE_GYRO_ROLL_RIGHT);
    state.PopulateAxis(ButtonType::WIIMOTE_GYRO_YAW_LEFT);
    state.PopulateAxis(ButtonType::WIIMOTE_GYRO_YAW_RIGHT);

    // Nunchuk IMU
    state.PopulateAxis(ButtonType::NUNCHUK_ACCEL_LEFT);
    state.PopulateAxis(ButtonType::NUNCHUK_ACCEL_RIGHT);
    state.PopulateAxis(ButtonType::NUNCHUK_ACCEL_FORWARD);
    state.PopulateAxis(ButtonType::NUNCHUK_ACCEL_BACKWARD);
    state.PopulateAxis(ButtonType::NUNCHUK_ACCEL_UP);
    state.PopulateAxis(ButtonType::NUNCHUK_ACCEL_DOWN);

    m_controllers.push_back(state);
  }
}

void StateManager::Init()
{
  for (size_t i = 0; i < m_controllers.size(); i++)
  {
    for (auto& button : m_controllers[i].m_buttons)
    {
      button.second = false;
    }
    
    for (auto& axis : m_controllers[i].m_axes)
    {
      axis.second = 0.0f;
    }
  }
}

void StateManager::DeInit()
{
}

bool StateManager::GetButtonPressed(int controller_id, ButtonType button) const
{
  return m_controllers[controller_id].m_buttons.at(button);
}

void StateManager::SetButtonPressed(int controller_id, ButtonType button, bool pressed)
{
  m_controllers[controller_id].m_buttons[button] = pressed;
}

float StateManager::GetAxisValue(int controller_id, ButtonType axis) const
{
  return m_controllers[controller_id].m_axes.at(axis);
}

void StateManager::SetAxisValue(int controller_id, ButtonType axis, float value)
{
  m_controllers[controller_id].m_axes[axis] = value;
}
}  // namespace ciface::iOS
