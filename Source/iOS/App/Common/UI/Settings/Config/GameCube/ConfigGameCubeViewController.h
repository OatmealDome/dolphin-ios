// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

#import "DOLSwitch.h"

NS_ASSUME_NONNULL_BEGIN

@interface ConfigGameCubeViewController : UITableViewController

@property (weak, nonatomic) IBOutlet DOLSwitch* mainMenuSwitch;
@property (weak, nonatomic) IBOutlet UILabel* languageLabel;

@end

NS_ASSUME_NONNULL_END
