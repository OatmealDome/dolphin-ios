// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include "InputCommon/ControllerInterface/iOS/MFiController.h"

#include "InputCommon/ControllerInterface/iOS/Motor.h"
#include "InputCommon/ControllerInterface/ControllerInterface.h"

namespace ciface::iOS
{
MFiController::MFiController(GCController* controller) : m_controller(controller)
{
  if (controller.extendedGamepad != nil)
  {
    GCExtendedGamepad* gamepad = controller.extendedGamepad;
    AddInput(new Button(gamepad.buttonA, "Button A"));
    AddInput(new Button(gamepad.buttonB, "Button B"));
    AddInput(new Button(gamepad.buttonX, "Button X"));
    AddInput(new Button(gamepad.buttonY, "Button Y"));
    AddInput(new Button(gamepad.dpad.up, "D-Pad Up"));
    AddInput(new Button(gamepad.dpad.down, "D-Pad Down"));
    AddInput(new Button(gamepad.dpad.left, "D-Pad Left"));
    AddInput(new Button(gamepad.dpad.right, "D-Pad Right"));
    AddInput(new PressureSensitiveButton(gamepad.leftShoulder, "L Shoulder"));
    AddInput(new PressureSensitiveButton(gamepad.rightShoulder, "R Shoulder"));
    AddInput(new PressureSensitiveButton(gamepad.leftTrigger, "L Trigger"));
    AddInput(new PressureSensitiveButton(gamepad.rightTrigger, "R Trigger"));
    AddInput(new Axis(gamepad.leftThumbstick.xAxis, 1.0f, "L Stick X+"));
    AddInput(new Axis(gamepad.leftThumbstick.xAxis, -1.0f, "L Stick X-"));
    AddInput(new Axis(gamepad.leftThumbstick.yAxis, 1.0f, "L Stick Y+"));
    AddInput(new Axis(gamepad.leftThumbstick.yAxis, -1.0f, "L Stick Y-"));
    AddInput(new Axis(gamepad.rightThumbstick.xAxis, 1.0f, "R Stick X+"));
    AddInput(new Axis(gamepad.rightThumbstick.xAxis, -1.0f, "R Stick X-"));
    AddInput(new Axis(gamepad.rightThumbstick.yAxis, 1.0f, "R Stick Y+"));
    AddInput(new Axis(gamepad.rightThumbstick.yAxis, -1.0f, "R Stick Y-"));

    // Optionals and buttons only on newer iOS versions

    if (@available(iOS 14.5, *))
    {
      if ([gamepad isKindOfClass:[GCDualSenseGamepad class]])
      {
        GCDualSenseGamepad* ds_gamepad = (GCDualSenseGamepad*)gamepad;
        AddInput(new Button(ds_gamepad.touchpadButton, "Touchpad"));
        
        // The user's first finger on the touchpad.
        AddInput(new Axis(ds_gamepad.touchpadPrimary.xAxis, 1.0f, "Touchpad X+"));
        AddInput(new Axis(ds_gamepad.touchpadPrimary.xAxis, -1.0f, "Touchpad X-"));
        AddInput(new Axis(ds_gamepad.touchpadPrimary.yAxis, 1.0f, "Touchpad Y+"));
        AddInput(new Axis(ds_gamepad.touchpadPrimary.yAxis, -1.0f, "Touchpad Y-"));

        // The user's second finger on the touchpad.
        AddInput(new Axis(ds_gamepad.touchpadSecondary.xAxis, 1.0f, "Touchpad Secondary X+"));
        AddInput(new Axis(ds_gamepad.touchpadSecondary.xAxis, -1.0f, "Touchpad Secondary X-"));
        AddInput(new Axis(ds_gamepad.touchpadSecondary.yAxis, 1.0f, "Touchpad Secondary Y+"));
        AddInput(new Axis(ds_gamepad.touchpadSecondary.yAxis, -1.0f, "Touchpad Secondary Y-"));
      }
    }

    if (@available(iOS 14, *))
    {
      if (gamepad.buttonHome != nil)
      {
        AddInput(new Button(gamepad.buttonHome, "Home"));
      }
      
      if ([gamepad isKindOfClass:[GCDualShockGamepad class]])
      {
        GCDualShockGamepad* ds_gamepad = (GCDualShockGamepad*)gamepad;
        AddInput(new Button(ds_gamepad.touchpadButton, "Touchpad"));
        
        // The user's first finger on the touchpad.
        AddInput(new Axis(ds_gamepad.touchpadPrimary.xAxis, 1.0f, "Touchpad X+"));
        AddInput(new Axis(ds_gamepad.touchpadPrimary.xAxis, -1.0f, "Touchpad X-"));
        AddInput(new Axis(ds_gamepad.touchpadPrimary.yAxis, 1.0f, "Touchpad Y+"));
        AddInput(new Axis(ds_gamepad.touchpadPrimary.yAxis, -1.0f, "Touchpad Y-"));

        // The user's second finger on the touchpad.
        AddInput(new Axis(ds_gamepad.touchpadSecondary.xAxis, 1.0f, "Touchpad Secondary X+"));
        AddInput(new Axis(ds_gamepad.touchpadSecondary.xAxis, -1.0f, "Touchpad Secondary X-"));
        AddInput(new Axis(ds_gamepad.touchpadSecondary.yAxis, 1.0f, "Touchpad Secondary Y+"));
        AddInput(new Axis(ds_gamepad.touchpadSecondary.yAxis, -1.0f, "Touchpad Secondary Y-"));
      }
      else if ([gamepad isKindOfClass:[GCXboxGamepad class]])
      {
        GCXboxGamepad* xbox_gamepad = (GCXboxGamepad*)gamepad;
        AddInput(new Button(xbox_gamepad.paddleButton1, "Paddle 1"));
        AddInput(new Button(xbox_gamepad.paddleButton2, "Paddle 2"));
        AddInput(new Button(xbox_gamepad.paddleButton3, "Paddle 3"));
        AddInput(new Button(xbox_gamepad.paddleButton4, "Paddle 4"));
      }
    }

    if (@available(iOS 13, *))
    {
      AddInput(new Button(gamepad.buttonMenu, "Menu"));

      if (gamepad.buttonOptions != nil)
      {
        AddInput(new Button(gamepad.buttonOptions, "Options"));
      }
    }

    if (@available(iOS 12.1, *))
    {
      if (gamepad.leftThumbstickButton != nil)
      {
        AddInput(new Button(gamepad.leftThumbstickButton, "L Stick"));
      }

      if (gamepad.rightThumbstickButton != nil)
      {
        AddInput(new Button(gamepad.rightThumbstickButton, "R Stick"));
      }
    }
  }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  else if (controller.gamepad != nil)
  {
    // Deprecated in iOS 10, but needed for some older controllers
    GCGamepad* gamepad = controller.gamepad;
    AddInput(new Button(gamepad.buttonA, "Button A"));
    AddInput(new Button(gamepad.buttonB, "Button B"));
    AddInput(new Button(gamepad.buttonX, "Button X"));
    AddInput(new Button(gamepad.buttonY, "Button Y"));
    AddInput(new Button(gamepad.dpad.up, "D-Pad Up"));
    AddInput(new Button(gamepad.dpad.down, "D-Pad Down"));
    AddInput(new Button(gamepad.dpad.left, "D-Pad Left"));
    AddInput(new Button(gamepad.dpad.right, "D-Pad Right"));
    AddInput(new PressureSensitiveButton(gamepad.leftShoulder, "L Shoulder"));
    AddInput(new PressureSensitiveButton(gamepad.rightShoulder, "R Shoulder"));
  }
#pragma clang diagnostic pop
  else if (controller.microGamepad != nil)  // Siri Remote
  {
    GCMicroGamepad* gamepad = controller.microGamepad;
    AddInput(new Button(gamepad.dpad.up, "D-Pad Up"));
    AddInput(new Button(gamepad.dpad.down, "D-Pad Down"));
    AddInput(new Button(gamepad.dpad.left, "D-Pad Left"));
    AddInput(new Button(gamepad.dpad.right, "D-Pad Right"));
    AddInput(new Button(gamepad.buttonA, "Button A"));
    AddInput(new Button(gamepad.buttonX, "Button X"));

    if (@available(iOS 13, *))
    {
      AddInput(new Button(gamepad.buttonMenu, "Menu"));
    }
  }

  if (controller.motion != nil)
  {
    GCMotion* motion = controller.motion;

    if (@available(iOS 14.0, *))
    {
      // The DualShock 4 requires manual sensor activation
      if (motion.sensorsRequireManualActivation)
      {
        motion.sensorsActive = true;
      }
    }
    
    AddInput(new AccelerometerAxis(motion, X, -1.0, "Accel Left"));
    AddInput(new AccelerometerAxis(motion, X, 1.0, "Accel Right"));
    AddInput(new AccelerometerAxis(motion, Y, 1.0, "Accel Forward"));
    AddInput(new AccelerometerAxis(motion, Y, -1.0, "Accel Back"));
    AddInput(new AccelerometerAxis(motion, Z, 1.0, "Accel Up"));
    AddInput(new AccelerometerAxis(motion, Z, -1.0, "Accel Down"));
    
    m_supports_accelerometer = true;

    if (@available(iOS 14.0, *))
    {
      m_supports_gyroscope = motion.hasRotationRate;
    }
    else
    {
      m_supports_gyroscope = motion.hasAttitudeAndRotationRate;
    }

    if (m_supports_gyroscope)
    {
      AddInput(new GyroscopeAxis(motion, X, 1.0, "Gyro Pitch Up"));
      AddInput(new GyroscopeAxis(motion, X, -1.0, "Gyro Pitch Down"));
      AddInput(new GyroscopeAxis(motion, Y, -1.0, "Gyro Roll Left"));
      AddInput(new GyroscopeAxis(motion, Y, 1.0, "Gyro Roll Right"));
      AddInput(new GyroscopeAxis(motion, Z, -1.0, "Gyro Yaw Left"));
      AddInput(new GyroscopeAxis(motion, Z, 1.0, "Gyro Yaw Right"));
    }
  }
  else
  {
    m_supports_accelerometer = false;
  }

  if (@available(iOS 14.0, *))
  {
    GCDeviceHaptics* haptics = controller.haptics;
    if (haptics != nil)
    {
      CHHapticEngine* engine = [haptics createEngineWithLocality:GCHapticsLocalityDefault];
      
      AddOutput(new Motor(std::move(engine), "Rumble"));
    }
  }
}

std::string MFiController::GetName() const
{
  NSString* vendor_name = [m_controller vendorName];
  if (vendor_name != nil)
  {
    return std::string([vendor_name UTF8String]);
  }
  else
  {
    return "Unknown Controller";
  }
}

std::string MFiController::GetSource() const
{
  return "MFi";
}

bool MFiController::SupportsAccelerometer() const
{
  return m_supports_accelerometer;
}

bool MFiController::SupportsGyroscope() const
{
  return m_supports_gyroscope;
}

bool MFiController::IsSameController(GCController* controller) const
{
  return m_controller == controller;
}

std::string MFiController::Button::GetName() const
{
  return m_name;
}

ControlState MFiController::Button::GetState() const
{
  return [m_input isPressed];
}

std::string MFiController::PressureSensitiveButton::GetName() const
{
  return m_name;
}

ControlState MFiController::PressureSensitiveButton::GetState() const
{
  return [m_input value];
}

std::string MFiController::Axis::GetName() const
{
  return m_name;
}

ControlState MFiController::Axis::GetState() const
{
  return [m_input value] * m_multiplier;
}

MFiController::AccelerometerAxis::AccelerometerAxis(GCMotion* motion, MotionPlane plane,
                                                    const double multiplier, const std::string name)
    : m_motion(motion), m_plane(plane), m_name(name)
{
  if (plane == X || plane == Y)
  {
    m_multiplier = -1.0;
  }
  else  // Z
  {
    m_multiplier = 1.0;
  }

  m_multiplier *= multiplier;
}

std::string MFiController::AccelerometerAxis::GetName() const
{
  return m_name;
}

ControlState MFiController::AccelerometerAxis::GetState() const
{
  if (@available(iOS 14.0, *))
  {
    // The DualShock 4 only returns combined gravity + acceleration.
    if ([m_motion hasGravityAndUserAcceleration])
    {
      GCAcceleration totalAcceleration = [m_motion acceleration];
      
      switch (m_plane)
      {
      case X:
        return totalAcceleration.x * m_multiplier;
      case Y:
        return totalAcceleration.y * m_multiplier;
      case Z:
        return totalAcceleration.z * m_multiplier;
      }
    }
  }
  
  GCAcceleration acceleration = [m_motion userAcceleration];
  GCAcceleration gravity = [m_motion gravity];

  switch (m_plane)
  {
  case X:
    return acceleration.x * gravity.x * m_multiplier;
  case Y:
    return acceleration.y * gravity.y * m_multiplier;
  case Z:
    return acceleration.z * gravity.z * m_multiplier;
  }
}

MFiController::GyroscopeAxis::GyroscopeAxis(GCMotion* motion, MotionPlane plane,
                                         const double multiplier, const std::string name)
    : m_motion(motion), m_plane(plane), m_name(name)
{
  if (plane == X || plane == Y)
  {
    m_multiplier = -1.0;
  }
  else  // Z
  {
    m_multiplier = 1.0;
  }

  m_multiplier *= multiplier;
}

std::string MFiController::GyroscopeAxis::GetName() const
{
  return m_name;
}

ControlState MFiController::GyroscopeAxis::GetState() const
{
  switch (m_plane)
  {
  case X:
    return [m_motion rotationRate].x * m_multiplier;
  case Y:
    return [m_motion rotationRate].y * m_multiplier;
  case Z:
    return [m_motion rotationRate].z * m_multiplier;
  }
}
}  // namespace ciface::iOS
