// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

@class EmulationBootParameter;
@class UIView;

NS_ASSUME_NONNULL_BEGIN

@interface EmulationCoordinator : NSObject

+ (EmulationCoordinator*)shared;

- (void)registerMainDisplayView:(UIView*)mainView;
- (void)runEmulationWithBootParameter:(EmulationBootParameter*)bootParameter;

@end

NS_ASSUME_NONNULL_END
