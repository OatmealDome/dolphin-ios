// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include "InputCommon/ControllerInterface/ControllerInterface.h"
#include "InputCommon/ControllerInterface/iOS/ButtonType.h"

namespace ciface::iOS
{
class Touchscreen : public Core::Device
{
private:
  class Button : public Input
  {
  public:
    std::string GetName() const override;
    Button(int controller_id, ButtonType index) : m_controller_id(controller_id), m_index(index) {}
    ControlState GetState() const override;

  private:
    const int m_controller_id;
    const ButtonType m_index;
  };
  class Axis : public Input
  {
  public:
    std::string GetName() const override;
    bool IsDetectable() const override { return false; }
    Axis(int controller_id, ButtonType index, float neg = 1.0f)
        : m_controller_id(controller_id), m_index(index), m_neg(neg)
    {
    }
    ControlState GetState() const override;

  private:
    const int m_controller_id;
    const ButtonType m_index;
    const float m_neg;
  };
  class Motor : public Core::Device::Output
  {
  public:
    Motor(int controller_id, ButtonType index) : m_controller_id(controller_id), m_index(index) {}
    ~Motor();
    std::string GetName() const override;
    void SetState(ControlState state) override;

  private:
    const int m_controller_id;
    const ButtonType m_index;
  };

public:
  Touchscreen(int controller_id, bool wiimote);
  ~Touchscreen() {}
  std::string GetName() const override;
  std::string GetSource() const override;

private:
  const int m_controller_id;
};
}  // namespace ciface::iOS
