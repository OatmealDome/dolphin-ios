// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class UIView;

@interface VirtualMFiControllerManager : NSObject

+ (VirtualMFiControllerManager*)shared;

@property (nonatomic) bool shouldConnectController;

- (void)connectControllerToView:(UIView*)superview API_AVAILABLE(ios(15.0));
- (void)disconnectController API_AVAILABLE(ios(15.0));

@end

NS_ASSUME_NONNULL_END
