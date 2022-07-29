// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

@class MappingDeviceViewController;

NS_ASSUME_NONNULL_BEGIN

@protocol MappingDeviceViewControllerDelegate <NSObject>

- (void)deviceDidChange:(MappingDeviceViewController*)viewController;

@end

NS_ASSUME_NONNULL_END
