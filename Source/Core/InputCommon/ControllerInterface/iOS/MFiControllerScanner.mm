// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include "InputCommon/ControllerInterface/iOS/MFiControllerScanner.h"

#include <GameController/GameController.h>

#include "InputCommon/ControllerInterface/ControllerInterface.h"
#include "InputCommon/ControllerInterface/iOS/MFiController.h"

@implementation MFiControllerScanner

- (id)init
{
  if (self = [super init])
  {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(controllerConnected:)
                                                 name:GCControllerDidConnectNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(controllerDisconnected:)
                                                 name:GCControllerDidDisconnectNotification
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

@end
