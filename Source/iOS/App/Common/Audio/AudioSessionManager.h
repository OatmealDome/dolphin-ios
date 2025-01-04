// Copyright 2025 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioSessionManager : NSObject

+ (AudioSessionManager*)shared;

- (void)setSessionCategory;

@end

NS_ASSUME_NONNULL_END
