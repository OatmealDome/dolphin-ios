// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

@protocol ControllersAddDsuServerViewControllerDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface ControllersAddDsuServerViewController : UITableViewController

@property (weak, nonatomic, nullable) id<ControllersAddDsuServerViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UITextField* descriptionField;
@property (weak, nonatomic) IBOutlet UITextField* addressField;
@property (weak, nonatomic) IBOutlet UITextField* portField;

- (IBAction)addPressed:(id)sender;

@end

NS_ASSUME_NONNULL_END
