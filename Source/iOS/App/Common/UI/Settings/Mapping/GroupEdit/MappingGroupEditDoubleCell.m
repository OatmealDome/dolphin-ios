// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "MappingGroupEditDoubleCell.h"

#import "MappingGroupEditDoubleCellDelegate.h"

@implementation MappingGroupEditDoubleCell

- (void)awakeFromNib {
  [super awakeFromNib];
  
  if (self.textField.inputAccessoryView == nil) {
    UIToolbar* toolbar = [[UIToolbar alloc] init];
    toolbar.items = @[
      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed)]
    ];
    
    [toolbar sizeToFit];
    
    self.textField.inputAccessoryView = toolbar;
  }
}

- (void)donePressed {
  [self endEditing:false];
  
  [self.delegate textFieldDidChange:self];
}

@end
