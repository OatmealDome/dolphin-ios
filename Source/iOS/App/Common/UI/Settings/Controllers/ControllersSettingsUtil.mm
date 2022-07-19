// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "ControllersSettingsUtil.h"

#import "Core/HW/SI/SI_Device.h"

#import "LocalizationUtil.h"

@implementation ControllersSettingsUtil

+ (NSString*)getLocalizedStringForSIDevice:(SerialInterface::SIDevices)device {
  NSString* localizable;
  switch (device) {
    case SerialInterface::SIDEVICE_NONE:
      localizable = @"None";
      break;
    case SerialInterface::SIDEVICE_GC_CONTROLLER:
      localizable = @"Standard Controller";
      break;
    case SerialInterface::SIDEVICE_WIIU_ADAPTER:
      localizable = @"GameCube Adapter for Wii U";
      break;
    case SerialInterface::SIDEVICE_GC_STEERING:
      localizable = @"Steering Wheel";
      break;
    case SerialInterface::SIDEVICE_DANCEMAT:
      localizable = @"Dance Mat";
      break;
    case SerialInterface::SIDEVICE_GC_TARUKONGA:
      localizable = @"DK Bongos";
      break;
    case SerialInterface::SIDEVICE_GC_GBA_EMULATED:
      localizable = @"GBA (Integrated)";
      break;
    case SerialInterface::SIDEVICE_GC_GBA:
      localizable = @"GBA (TCP)";
      break;
    case SerialInterface::SIDEVICE_GC_KEYBOARD:
      localizable = @"Keyboard";
      break;
    default:
      localizable = @"Error";
      break;
  }
  
  return DOLCoreLocalizedString(localizable);
}

@end
