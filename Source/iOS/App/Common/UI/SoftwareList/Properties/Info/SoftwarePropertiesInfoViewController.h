// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

@class GameFilePtrWrapper;

NS_ASSUME_NONNULL_BEGIN

@interface SoftwarePropertiesInfoViewController : UITableViewController

@property (nonatomic) GameFilePtrWrapper* gameFileWrapper;

@property (weak, nonatomic) IBOutlet UILabel* nameLabel;
@property (weak, nonatomic) IBOutlet UILabel* idLabel;
@property (weak, nonatomic) IBOutlet UILabel* countryLabel;
@property (weak, nonatomic) IBOutlet UILabel* makerLabel;
@property (weak, nonatomic) IBOutlet UILabel* apploaderLabel;


@end

NS_ASSUME_NONNULL_END
