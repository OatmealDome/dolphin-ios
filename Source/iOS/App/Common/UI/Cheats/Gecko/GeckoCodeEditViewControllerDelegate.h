// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

@class GeckoCodeEditViewController;

NS_ASSUME_NONNULL_BEGIN

@protocol GeckoCodeEditViewControllerDelegate <NSObject>

- (void)userDidSaveCode:(GeckoCodeEditViewController*)viewController;

@end

NS_ASSUME_NONNULL_END
