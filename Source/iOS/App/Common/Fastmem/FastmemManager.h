// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FastmemManager : NSObject

+ (FastmemManager*)shared;

@property (readonly) bool fastmemAvailable;

@end

NS_ASSUME_NONNULL_END
