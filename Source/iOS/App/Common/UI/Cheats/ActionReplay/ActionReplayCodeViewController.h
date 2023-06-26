// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <string>

#import <UIKit/UIKit.h>

#import "Common/CommonTypes.h"

NS_ASSUME_NONNULL_BEGIN

@interface ActionReplayCodeViewController : UITableViewController

@property (nonatomic) std::string gameId;
@property (nonatomic) u16 revision;

@end

NS_ASSUME_NONNULL_END
