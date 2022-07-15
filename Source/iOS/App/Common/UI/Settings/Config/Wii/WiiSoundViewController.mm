// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "WiiSoundViewController.h"

#import "Core/Config/SYSCONFSettings.h"

@interface WiiSoundViewController ()

@end

@implementation WiiSoundViewController {
  NSInteger _lastSelected;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  _lastSelected = Config::Get(Config::SYSCONF_SOUND_MODE);
  
  UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_lastSelected inSection:0]];
  [cell setAccessoryType:UITableViewCellAccessoryCheckmark];

}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  if (_lastSelected != indexPath.row) {
    Config::SetBase(Config::SYSCONF_SOUND_MODE, (int)indexPath.row);
    
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    UITableViewCell* oldCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_lastSelected inSection:0]];
    oldCell.accessoryType = UITableViewCellAccessoryNone;
    
    _lastSelected = indexPath.row;
  }
  
  [tableView deselectRowAtIndexPath:indexPath animated:true];
}

@end
