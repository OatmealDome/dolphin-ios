// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

@class UIWindowScene;

NS_ASSUME_NONNULL_BEGIN

@interface MsgAlertManager : NSObject

+ (MsgAlertManager*)shared;

- (void)registerHandler;
- (void)registerMainDisplayScene:(nullable UIWindowScene*)scene;

@end

NS_ASSUME_NONNULL_END
