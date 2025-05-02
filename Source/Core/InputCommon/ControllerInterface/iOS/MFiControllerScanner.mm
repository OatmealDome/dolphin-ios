// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include "InputCommon/ControllerInterface/iOS/MFiControllerScanner.h"

#include <GameController/GameController.h>

#include "InputCommon/ControllerInterface/ControllerInterface.h"
#include "InputCommon/ControllerInterface/iOS/MFiController.h"
#include "InputCommon/ControllerInterface/iOS/MFiKeyboard.h"

@implementation MFiControllerScanner

- (id)init
{
  if (self = [super init])
  {
    _keyboards = [[NSMutableArray alloc] init];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(controllerConnected:)
                                                 name:GCControllerDidConnectNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(controllerDisconnected:)
                                                 name:GCControllerDidDisconnectNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardConnected:)
                                                 name:GCKeyboardDidConnectNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDisconnected:)
                                                 name:GCKeyboardDidDisconnectNotification
                                               object:nil];
  }

  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)controllerConnected:(NSNotification*)notification
{
  GCController* controller = (GCController*)notification.object;
  g_controller_interface.AddDevice(std::make_shared<ciface::iOS::MFiController>(controller));
}

- (void)controllerDisconnected:(NSNotification*)notification
{
  GCController* gc_controller = (GCController*)notification.object;
  g_controller_interface.RemoveDevice([&gc_controller](const auto* device) {
    const ciface::iOS::MFiController* controller =
        dynamic_cast<const ciface::iOS::MFiController*>(device);
    return controller && controller->IsSameController(gc_controller);
  });
}

- (void)keyboardConnected:(NSNotification*)notification
{
  GCKeyboard* keyboard = (GCKeyboard*)notification.object;
  g_controller_interface.AddDevice(std::make_shared<ciface::iOS::MFiKeyboard>(keyboard));
  [_keyboards addObject:keyboard];
}

- (void)keyboardDisconnected:(NSNotification*)notification
{
  g_controller_interface.RemoveDevice([](const auto* device) {
    const ciface::iOS::MFiKeyboard* keyboard =
        dynamic_cast<const ciface::iOS::MFiKeyboard*>(device);
    return keyboard != nullptr;
  });
  [_keyboards removeObject:notification.object];
}

@end
