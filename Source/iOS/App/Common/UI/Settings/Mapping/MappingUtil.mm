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

// This is super unwieldy...
+ (void)detectExpressionWithDefaultDevice:(const ciface::Core::DeviceQualifier&)defaultDevice
                               allDevices:(bool)allDevices
                                    quote:(ciface::MappingCommon::Quote)quote
                           viewController:(UIViewController*)viewController
                                 callback:(void (^)(std::string))callback {
  // TODO: Localization
  UIAlertController* inputAlert = [UIAlertController alertControllerWithTitle:@"Detecting Input" message:nil preferredStyle:UIAlertControllerStyleAlert];
  
  [viewController presentViewController:inputAlert animated:true completion:^{
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
      constexpr auto initial_time = std::chrono::seconds(3);
      constexpr auto confirmation_time = std::chrono::milliseconds(0);
      constexpr auto maximum_time = std::chrono::seconds(5);
    
      std::vector<std::string> devices;
      
      if (allDevices) {
        devices = g_controller_interface.GetAllDeviceStrings();
      } else {
        devices = {defaultDevice.ToString()};
      }
      
      auto detections = g_controller_interface.DetectInput(devices, initial_time, confirmation_time, maximum_time);
      
      ciface::MappingCommon::RemoveSpuriousTriggerCombinations(&detections);
      
      std::string expression = BuildExpression(detections, defaultDevice, quote);
      
      dispatch_async(dispatch_get_main_queue(), ^{
        [viewController dismissViewControllerAnimated:true completion:^{
          callback(expression);
          
          if (expression.empty()) {
            UIAlertController* noInputAlert = [UIAlertController alertControllerWithTitle:@"No input was detected." message:nil preferredStyle:UIAlertControllerStyleAlert];
            [noInputAlert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"OK") style:UIAlertActionStyleDefault handler:nil]];
            
            [viewController presentViewController:noInputAlert animated:true completion:nil];
          }
        }];
      });
    });
  }];
}

@end
