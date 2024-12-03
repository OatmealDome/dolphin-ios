// Copyright 2024 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^LowPowerModeDidChangeHandler)(BOOL);

@interface LowPowerModeManager : NSObject

@property(readonly, getter=isLowPowerModeEnabled) BOOL lowPowerModeEnabled;

@property(strong, nonatomic, nullable) void (^lowPowerModeDidChangeHandler)(BOOL);

+ (instancetype)shared;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
