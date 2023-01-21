// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

namespace ControllerEmu {
class EmulatedController;
}

class InputConfig;

@protocol MappingDeviceViewControllerDelegate;

typedef NS_ENUM(NSUInteger, DOLDeviceFilter) {
  DOLDeviceFilterNone,
  DOLDeviceFilterTouchscreenExceptPad,
  DOLDeviceFilterTouchscreenExceptWii,
  DOLDeviceFilterTouchscreenAll
};

NS_ASSUME_NONNULL_BEGIN

@interface MappingDeviceViewController : UITableViewController

@property (weak, nonatomic, nullable) id<MappingDeviceViewControllerDelegate> delegate;

@property (nonatomic) DOLDeviceFilter filterType;
@property (nonatomic) InputConfig* inputConfig;
@property (nonatomic) ControllerEmu::EmulatedController* emulatedController;

@end

NS_ASSUME_NONNULL_END
