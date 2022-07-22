// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "MappingExtensionViewController.h"

#import "InputCommon/ControllerEmu/ControlGroup/Attachments.h"

#import "FoundationStringUtil.h"
#import "LocalizationUtil.h"
#import "MappingExtensionCell.h"
#import "MappingExtensionViewControllerDelegate.h"
#import "MappingUtil.h"

@interface MappingExtensionViewController ()

@end

@implementation MappingExtensionViewController

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
  return self.attachments->GetAttachmentList().size();
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  const auto& attachment = self.attachments->GetAttachmentList()[indexPath.row];
  
  MappingExtensionCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ExtensionCell" forIndexPath:indexPath];
  
  cell.extensionLabel.text = DOLCoreLocalizedString(CppToFoundationString(attachment->GetDisplayName()));
  
  if (indexPath.row == self.attachments->GetSelectedAttachment()) {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  } else {
    cell.accessoryType = UITableViewCellAccessoryNone;
  }
  
  return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  int selectedAttachment = self.attachments->GetSelectedAttachment();
  
  if (selectedAttachment != indexPath.row) {
    self.attachments->SetSelectedAttachment((u32)indexPath.row);
    
    MappingExtensionCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    MappingExtensionCell* oldCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedAttachment inSection:0]];
    oldCell.accessoryType = UITableViewCellAccessoryNone;
    
    [self.delegate extensionDidChange:self];
  }
  
  [tableView deselectRowAtIndexPath:indexPath animated:true];
}

@end
