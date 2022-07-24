// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

@class MappingLoadProfileViewController;

NS_ASSUME_NONNULL_BEGIN

@protocol MappingLoadProfileViewControllerDelegate <NSObject>

- (void)profileDidLoad:(MappingLoadProfileViewController*)viewController;

@end

NS_ASSUME_NONNULL_END
