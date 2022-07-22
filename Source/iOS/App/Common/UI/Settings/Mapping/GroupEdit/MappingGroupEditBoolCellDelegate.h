// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

@class MappingGroupEditBoolCell;

NS_ASSUME_NONNULL_BEGIN

@protocol MappingGroupEditBoolCellDelegate <NSObject>

- (void)switchDidChange:(MappingGroupEditBoolCell*)cell;

@end

NS_ASSUME_NONNULL_END
