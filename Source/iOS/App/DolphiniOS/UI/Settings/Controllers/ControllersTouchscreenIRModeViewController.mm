// Copyright 2024 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "ControllersTouchscreenIRModeViewController.h"

#import "Core/Config/iOSSettings.h"

@interface ControllersTouchscreenIRModeViewController ()

@end

@implementation ControllersTouchscreenIRModeViewController {
  NSInteger _lastSelected;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  _lastSelected = Config::Get(Config::MAIN_TOUCH_PAD_IR_MODE);
  
  UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_lastSelected inSection:0]];
  [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  if (_lastSelected != indexPath.row) {
    Config::SetBaseOrCurrent(Config::MAIN_TOUCH_PAD_IR_MODE, (int)indexPath.row);
    
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    UITableViewCell* oldCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_lastSelected inSection:0]];
    oldCell.accessoryType = UITableViewCellAccessoryNone;
    
    _lastSelected = indexPath.row;
  }
  
  [tableView deselectRowAtIndexPath:indexPath animated:true];
}

@end
