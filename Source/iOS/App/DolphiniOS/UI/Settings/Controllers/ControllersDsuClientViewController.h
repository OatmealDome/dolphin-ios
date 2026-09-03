// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ControllersDsuClientViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UISwitch* enabledSwitch;
@property (weak, nonatomic) IBOutlet UITextView* descriptionTextView;

- (IBAction)enabledSwitchChanged:(id)sender;

@end

NS_ASSUME_NONNULL_END
