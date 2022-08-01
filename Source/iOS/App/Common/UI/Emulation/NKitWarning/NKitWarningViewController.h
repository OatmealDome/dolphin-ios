// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

#import "DOLSwitch.h"

@protocol NKitWarningViewControllerDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface NKitWarningViewController : UIViewController

@property (weak, nonatomic, nullable) id<NKitWarningViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet DOLSwitch* showSwitch;

@end

NS_ASSUME_NONNULL_END
