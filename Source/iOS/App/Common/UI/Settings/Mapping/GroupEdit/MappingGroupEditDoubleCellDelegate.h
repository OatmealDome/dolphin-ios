// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

@class MappingGroupEditDoubleCell;

NS_ASSUME_NONNULL_BEGIN

@protocol MappingGroupEditDoubleCellDelegate <NSObject>

- (void)textFieldDidChange:(MappingGroupEditDoubleCell*)cell;

@end

NS_ASSUME_NONNULL_END
