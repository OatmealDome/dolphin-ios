// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

@class ActionReplayCodeEditViewController;

NS_ASSUME_NONNULL_BEGIN

@protocol ActionReplayCodeEditViewControllerDelegate <NSObject>

- (void)userDidSaveCode:(ActionReplayCodeEditViewController*)viewController;

@end

NS_ASSUME_NONNULL_END
