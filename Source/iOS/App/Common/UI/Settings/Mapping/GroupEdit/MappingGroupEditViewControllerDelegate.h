// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

@class MappingGroupEditViewController;

NS_ASSUME_NONNULL_BEGIN

@protocol MappingGroupEditViewControllerDelegate <NSObject>

- (void)controlGroupDidChange:(MappingGroupEditViewController*)viewController;

@end

NS_ASSUME_NONNULL_END
