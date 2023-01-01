// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BootNoticeManager : NSObject

+ (BootNoticeManager*)shared;

- (void)enqueueViewController:(UIViewController*)viewController;
- (void)presentToSceneIfNecessary;

@end

NS_ASSUME_NONNULL_END
