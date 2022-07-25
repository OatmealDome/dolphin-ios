// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ExternalDisplayEmulationViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView* rendererView;
@property (weak, nonatomic) IBOutlet UIView* waitView;

@end

NS_ASSUME_NONNULL_END
