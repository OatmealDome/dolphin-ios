// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "MappingGroupEditEnabledCell.h"

#import "MappingGroupEditEnabledCellDelegate.h"

@implementation MappingGroupEditEnabledCell

- (void)awakeFromNib {
  [super awakeFromNib];
  
  [self.enabledSwitch addValueChangedTarget:self action:@selector(switchValueChanged)];
}

- (void)switchValueChanged {
  if (self.delegate != nil) {
    [self.delegate enableSwitchValueDidChange:self];
  }
}

@end
