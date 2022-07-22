// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

@class MappingExtensionViewController;

NS_ASSUME_NONNULL_BEGIN

@protocol MappingExtensionViewControllerDelegate <NSObject>

- (void)extensionDidChange:(MappingExtensionViewController*)viewController;

@end

NS_ASSUME_NONNULL_END
