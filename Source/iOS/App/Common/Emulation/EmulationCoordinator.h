// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

@class EmulationBootParameter;
@class UIView;

NS_ASSUME_NONNULL_BEGIN

NSString* const DOLEmulationDidStartNotification = @"DOLEmulationDidStartNotification";
NSString* const DOLEmulationDidEndNotification = @"DOLEmulationDidEndNotification";

@interface EmulationCoordinator : NSObject

+ (EmulationCoordinator*)shared;

@property (nonatomic, setter=setIsExternalDisplayConnected:) bool isExternalDisplayConnected;
@property (nonatomic) bool userRequestedPause;

- (void)registerMainDisplayView:(UIView*)mainView;
- (void)registerExternalDisplayView:(UIView*)externalView;
- (void)runEmulationWithBootParameter:(EmulationBootParameter*)bootParameter;
- (void)clearMetalLayer;

@end

NS_ASSUME_NONNULL_END
