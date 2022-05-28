// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TCManagerInterface : NSObject

+ (void)setButtonStateFor:(NSInteger)button controller:(NSInteger)controllerId state:(BOOL)state;
+ (void)setAxisValueFor:(NSInteger)axis controller:(NSInteger)controllerId value:(float)value;

@end

NS_ASSUME_NONNULL_END
