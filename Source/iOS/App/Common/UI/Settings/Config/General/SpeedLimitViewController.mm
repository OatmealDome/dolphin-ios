// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "SpeedLimitViewController.h"

#import "Core/Config/MainSettings.h"

#import "SpeedLimitCell.h"

@interface SpeedLimitViewController ()

@end

@implementation SpeedLimitViewController {
  NSInteger _lastSelected;
}

- (void)viewWillAppear:(BOOL)animated {
  _lastSelected = (NSInteger)(Config::Get(Config::MAIN_EMULATION_SPEED) * 10);
  
  [super viewWillAppear:animated];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  // Unlimited and 10% to 200% (increments of 10%)
  return 21;
}

- (UITableViewCell *)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  SpeedLimitCell* cell = [tableView dequeueReusableCellWithIdentifier:@"SpeedLimitCell" forIndexPath:indexPath];
  
  if (indexPath.row == 0) {
    cell.limitLabel.text = @"Unlimited";
  } else {
    NSInteger percent = indexPath.row * 10;
    
    if (percent == 100) {
      cell.limitLabel.text = [NSString stringWithFormat:@"%ld%% (Normal Speed)", indexPath.row * 10];
    } else {
      cell.limitLabel.text = [NSString stringWithFormat:@"%ld%%", percent];
    }
  }
  
  
  if (indexPath.row == _lastSelected) {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  } else {
    cell.accessoryType = UITableViewCellAccessoryNone;
  }

  return cell;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  if (_lastSelected != indexPath.row) {
    Config::SetBaseOrCurrent(Config::MAIN_EMULATION_SPEED, indexPath.row * 0.1f);

    SpeedLimitCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    UITableViewCell* oldCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_lastSelected inSection:0]];
    oldCell.accessoryType = UITableViewCellAccessoryNone;
    
    _lastSelected = indexPath.row;
  }
  
  [tableView deselectRowAtIndexPath:indexPath animated:true];
}

@end
