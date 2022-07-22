// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

#import "MappingGroupEditEnabledCellDelegate.h"

namespace ControllerEmu {
class EmulatedController;
class ControlGroup;
}

NS_ASSUME_NONNULL_BEGIN

@interface MappingGroupEditViewController : UITableViewController <MappingGroupEditEnabledCellDelegate>

@property (nonatomic) ControllerEmu::EmulatedController* controller;
@property (nonatomic) ControllerEmu::ControlGroup* controlGroup;

@end

NS_ASSUME_NONNULL_END
