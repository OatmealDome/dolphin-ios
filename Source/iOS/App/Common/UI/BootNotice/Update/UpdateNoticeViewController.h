// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UpdateNoticeViewController : UIViewController

@property (nonatomic) NSDictionary* updateInfo;

@property (weak, nonatomic) IBOutlet UILabel* versionLabel;
@property (weak, nonatomic) IBOutlet UILabel* changesLabel;
@property (weak, nonatomic) IBOutlet UILabel* saveStateLabel;

@end

NS_ASSUME_NONNULL_END
