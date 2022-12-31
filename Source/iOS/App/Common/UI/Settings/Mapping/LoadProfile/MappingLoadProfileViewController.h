// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

namespace ControllerEmu {
class EmulatedController;
}

class InputConfig;

@protocol MappingLoadProfileViewControllerDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface MappingLoadProfileViewController : UITableViewController

@property (weak, nonatomic, nullable) id<MappingLoadProfileViewControllerDelegate> delegate;

@property (nonatomic) InputConfig* inputConfig;
@property (nonatomic) ControllerEmu::EmulatedController* emulatedController;
@property (nonatomic) bool filterTouchscreen;

@end

NS_ASSUME_NONNULL_END
