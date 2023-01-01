// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

#import "DOLSwitch.h"

NS_ASSUME_NONNULL_BEGIN

@interface DebugRootViewController : UITableViewController

@property (weak, nonatomic) IBOutlet DOLSwitch* mfiSwitch;
@property (weak, nonatomic) IBOutlet UILabel* userFolderPathLabel;
@property (weak, nonatomic) IBOutlet UILabel* jitStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel* jitErrorLabel;

@end

NS_ASSUME_NONNULL_END
