// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JitManager : NSObject

@property (readonly, assign) bool acquiredJit;

+ (JitManager*)shared;

- (void)recheckIfJitIsAcquired;

@end

NS_ASSUME_NONNULL_END
