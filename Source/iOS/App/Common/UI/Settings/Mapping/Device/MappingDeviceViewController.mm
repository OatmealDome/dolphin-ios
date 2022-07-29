// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "MappingDeviceViewController.h"

#import <string>
#import <vector>

#import "InputCommon/ControllerEmu/ControllerEmu.h"
#import "InputCommon/ControllerInterface/ControllerInterface.h"

#import "FoundationStringUtil.h"
#import "LocalizationUtil.h"
#import "MappingDeviceCell.h"
#import "MappingDeviceViewControllerDelegate.h"

struct Device {
  std::string actualName;
  std::string uiName;
};

@interface MappingDeviceViewController ()

@end

@implementation MappingDeviceViewController {
  NSInteger _lastSelected;
  std::vector<std::string> _devices;
  NSMutableArray<NSString*>* _deviceNames;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  _deviceNames = [[NSMutableArray alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  [self repopulateDevices];
}

- (void)repopulateDevices {
  _devices.clear();
  [_deviceNames removeAllObjects];
  
  for (const auto& name : g_controller_interface.GetAllDeviceStrings()) {
    _devices.push_back(name);
    [_deviceNames addObject:CppToFoundationString(name)];
  }
  
  _lastSelected = -1;
  
  const std::string defaultDevice = self.emulatedController->GetDefaultDevice().ToString();
  
  if (defaultDevice.empty()) {
    return;
  }
  
  for (int i = 0; i < _devices.size(); i++) {
    if (_devices[i] == defaultDevice) {
      _lastSelected = i;
    }
  }
  
  if (_lastSelected == -1) {
    _devices.push_back(defaultDevice);
    
    NSString* foundationDeviceName = CppToFoundationString(defaultDevice);
    [_deviceNames addObject:[NSString stringWithFormat:@"[%@] %@", DOLCoreLocalizedString(@"disconnected"), foundationDeviceName]];
    
    _lastSelected = _devices.size() - 1;
  }
  
  [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
  return _devices.size();
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  MappingDeviceCell* cell = [tableView dequeueReusableCellWithIdentifier:@"DeviceCell" forIndexPath:indexPath];
  
  cell.deviceLabel.text = _deviceNames[indexPath.row];
  
  if (indexPath.row == _lastSelected) {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  } else {
    cell.accessoryType = UITableViewCellAccessoryNone;
  }
  
  return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  if (_lastSelected != indexPath.row) {
    self.emulatedController->SetDefaultDevice(_devices[indexPath.row]);
    self.emulatedController->UpdateReferences(g_controller_interface);
    
    MappingDeviceCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    if (_lastSelected != -1) {
      MappingDeviceCell* oldCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_lastSelected inSection:0]];
      oldCell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    _lastSelected = indexPath.row;
    
    [self.delegate deviceDidChange:self];
  }
  
  [tableView deselectRowAtIndexPath:indexPath animated:true];
}

@end
