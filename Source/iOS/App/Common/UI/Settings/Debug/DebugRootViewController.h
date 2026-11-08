// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

#import "DOLSwitch.h"

NS_ASSUME_NONNULL_BEGIN

@interface DebugRootViewController : UITableViewController

@property (weak, nonatomic) IBOutlet DOLSwitch* fastmemSwitch;
@property (weak, nonatomic) IBOutlet DOLSwitch* syncOnIdleSkipSwitch;
@property (weak, nonatomic) IBOutlet DOLSwitch* mfiSwitch;
@property (weak, nonatomic) IBOutlet DOLSwitch* forceJitScriptSwitch;
@property (weak, nonatomic) IBOutlet UILabel* userFolderPathLabel;
@property (weak, nonatomic) IBOutlet UILabel* jitStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel* jitErrorLabel;
@property (weak, nonatomic) IBOutlet UILabel* fastmemStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel* launchTimesLabel;
@property (weak, nonatomic) IBOutlet UIButton* jitLaunchModeButton;
@property (weak, nonatomic) IBOutlet UILabel* jitLaunchModeInfoLabel;
@property (weak, nonatomic) IBOutlet UILabel* importPairingFileStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel* preparationStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel* txmStatusLabel;

@end

NS_ASSUME_NONNULL_END
