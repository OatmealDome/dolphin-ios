// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

@class GameFilePtrWrapper;

NS_ASSUME_NONNULL_BEGIN

@interface SoftwarePropertiesViewController : UITableViewController

@property (nonatomic) GameFilePtrWrapper* gameFileWrapper;

@end

NS_ASSUME_NONNULL_END
