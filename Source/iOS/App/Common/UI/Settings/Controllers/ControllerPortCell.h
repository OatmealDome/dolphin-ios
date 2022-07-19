// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ControllerPortCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel* portLabel;
@property (weak, nonatomic) IBOutlet UILabel* typeLabel;

@end

NS_ASSUME_NONNULL_END
