// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

@protocol MappingGroupEditDoubleCellDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface MappingGroupEditDoubleCell : UITableViewCell

@property (weak, nonatomic, nullable) id<MappingGroupEditDoubleCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel* nameLabel;
@property (weak, nonatomic) IBOutlet UITextField* textField;

@end

NS_ASSUME_NONNULL_END
