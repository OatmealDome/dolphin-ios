// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <map>
#include <vector>

#include "InputCommon/ControllerInterface/iOS/ButtonType.h"

namespace ciface::iOS
{
class StateManager
{
private:
  class ControllerState
  {
  public:
    std::map<ButtonType, bool> m_buttons;
    std::map<ButtonType, float> m_axes;
    
    void PopulateButton(ButtonType button);
    void PopulateAxis(ButtonType axis);
  };

  static StateManager s_instance;

  std::vector<ControllerState*> m_controllers;
public:
  static StateManager* GetInstance() { return &s_instance; }

  void Init();
  void DeInit();

  bool GetButtonPressed(int controller_id, ButtonType button) const;
  void SetButtonPressed(int controller_id, ButtonType button, bool pressed);
  float GetAxisValue(int controller_id, ButtonType axis) const;
  void SetAxisValue(int controller_id, ButtonType axis, float value);
};
}  // namespace ciface::iOS
