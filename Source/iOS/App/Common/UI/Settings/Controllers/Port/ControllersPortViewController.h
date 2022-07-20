// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

#import "DOLControllerPortType.h"

NS_ASSUME_NONNULL_BEGIN

@interface ControllersPortViewController : UITableViewController

@property (nonatomic) DOLControllerPortType portType;
@property (nonatomic) int portNumber;

@property (weak, nonatomic) IBOutlet UILabel* typeLabel;
@property (weak, nonatomic) IBOutlet UITableViewCell* configureCell;
@property (weak, nonatomic) IBOutlet UILabel* configureLabel;

@end

NS_ASSUME_NONNULL_END
