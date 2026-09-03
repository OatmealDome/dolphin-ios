// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

@class ControllersAddDsuServerViewController;

NS_ASSUME_NONNULL_BEGIN

@protocol ControllersAddDsuServerViewControllerDelegate <NSObject>

- (void)addDsuServerViewController:(ControllersAddDsuServerViewController*)viewController
       didAddServerWithDescription:(NSString*)description
                            address:(NSString*)address
                               port:(uint16_t)port;

@end

NS_ASSUME_NONNULL_END
