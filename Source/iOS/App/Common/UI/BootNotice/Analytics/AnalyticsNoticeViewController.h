// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

#import "Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface AnalyticsNoticeViewController : UIViewController

@property (weak, nonatomic, nullable) id<AnalyticsNoticeViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
