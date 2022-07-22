// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "MappingGroupEditBoolCell.h"

#import "MappingGroupEditBoolCellDelegate.h"

@implementation MappingGroupEditBoolCell

- (void)awakeFromNib {
  [super awakeFromNib];
  
  [self.enabledSwitch addValueChangedTarget:self action:@selector(switchChanged)];
}

- (void)switchChanged {
  [self.delegate switchDidChange:self];
}

@end
