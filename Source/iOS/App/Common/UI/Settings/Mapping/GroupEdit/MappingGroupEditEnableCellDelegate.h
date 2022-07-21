// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

@class MappingGroupEditEnabledCell;

NS_ASSUME_NONNULL_BEGIN

@protocol MappingGroupEditEnableCellDelegate <NSObject>

- (void)enableSwitchValueDidChange:(MappingGroupEditEnabledCell*)cell;

@end

NS_ASSUME_NONNULL_END
