// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "MappingUtil.h"

#import <chrono>

#import <UIKit/UIKit.h>

#import "Core/HW/WiimoteEmu/WiimoteEmu.h"

#import "InputCommon/ControlReference/ControlReference.h"
#import "InputCommon/ControllerInterface/ControllerInterface.h"
#import "InputCommon/ControllerInterface/MappingCommon.h"

#import "FoundationStringUtil.h"
#import "LocalizationUtil.h"

@implementation MappingUtil

+ (NSString*)getLocalizedStringForWiimoteExtension:(WiimoteEmu::ExtensionNumber)extension {
  NSString* localizable;
  switch (extension) {
    case WiimoteEmu::ExtensionNumber::NONE:
      localizable = @"";
      break;
    case WiimoteEmu::ExtensionNumber::NUNCHUK:
      localizable = @"Nunchuk";
      break;
    case WiimoteEmu::ExtensionNumber::CLASSIC:
      localizable = @"Classic Controller";
      break;
    case WiimoteEmu::ExtensionNumber::GUITAR:
      localizable = @"Guitar";
      break;
    case WiimoteEmu::ExtensionNumber::DRUMS:
      localizable = @"Drum Kit";
      break;
    case WiimoteEmu::ExtensionNumber::TURNTABLE:
      localizable = @"DJ Turntable";
      break;
    case WiimoteEmu::ExtensionNumber::UDRAW_TABLET:
      localizable = @"uDraw GameTablet";
      break;
    case WiimoteEmu::ExtensionNumber::DRAWSOME_TABLET:
      localizable = @"Drawsome Tablet";
      break;
    case WiimoteEmu::ExtensionNumber::TATACON:
      localizable = @"Taiko Drum";
      break;
    default:
      localizable = @"Error";
      break;
  }
  
  return DOLCoreLocalizedString(localizable);
}

@end
