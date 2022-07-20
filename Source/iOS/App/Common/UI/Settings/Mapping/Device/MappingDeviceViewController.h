// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

namespace ControllerEmu {
class EmulatedController;
}

NS_ASSUME_NONNULL_BEGIN

@interface MappingDeviceViewController : UITableViewController

@property (nonatomic) ControllerEmu::EmulatedController* emulatedController;

@end

NS_ASSUME_NONNULL_END
