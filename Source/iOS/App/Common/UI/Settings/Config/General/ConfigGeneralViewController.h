// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

#import "DOLSwitch.h"

NS_ASSUME_NONNULL_BEGIN

@interface ConfigGeneralViewController : UITableViewController

@property (weak, nonatomic) IBOutlet DOLSwitch* dualCoreSwitch;
@property (weak, nonatomic) IBOutlet DOLSwitch* cheatsSwitch;
@property (weak, nonatomic) IBOutlet DOLSwitch* mismatchedRegionSwitch;
@property (weak, nonatomic) IBOutlet DOLSwitch* changeDiscsSwitch;
@property (weak, nonatomic) IBOutlet UILabel* speedLimitLabel;
@property (weak, nonatomic) IBOutlet UILabel* regionLabel;

@end

NS_ASSUME_NONNULL_END
