// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "ControllersTypeViewController.h"

#import <array>

#import "Core/Config/MainSettings.h"
#import "Core/Config/WiimoteSettings.h"
#import "Core/HW/SI/SI_Device.h"
#import "Core/HW/Wiimote.h"

#import "ControllersSettingsUtil.h"
#import "ControllersTypeCell.h"

@interface ControllersTypeViewController ()

@end

@implementation ControllersTypeViewController {
  NSInteger _lastSelected;
}

static const std::array<SerialInterface::SIDevices, 2> kSupportedPadDevices {
  SerialInterface::SIDEVICE_NONE,
  SerialInterface::SIDEVICE_GC_CONTROLLER
};

static const std::array<WiimoteSource, 2> kSupportedWiimoteSources {
  WiimoteSource::None,
  WiimoteSource::Emulated
};

- (void)viewDidLoad {
  [super viewDidLoad];
  
  _lastSelected = -1;
  
  if (self.portType == DOLControllerPortTypePad) {
    const SerialInterface::SIDevices siDevice = Config::Get(Config::GetInfoForSIDevice(self.portNumber));
    
    for (int i = 0; i < kSupportedPadDevices.size(); i++) {
      if (siDevice == kSupportedPadDevices[i]) {
        _lastSelected = i;
      }
    }
  } else {
    const WiimoteSource wiiSource = Config::Get(Config::GetInfoForWiimoteSource(self.portNumber));
    
    for (int i = 0; i < kSupportedWiimoteSources.size(); i++) {
      if (wiiSource == kSupportedWiimoteSources[i]) {
        _lastSelected = i;
      }
    }
  }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
  return self.portType == DOLControllerPortTypePad ? kSupportedPadDevices.size() : kSupportedWiimoteSources.size();
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  ControllersTypeCell* cell = [tableView dequeueReusableCellWithIdentifier:@"TypeCell" forIndexPath:indexPath];
  
  NSString* text;
  if (self.portType == DOLControllerPortTypePad) {
    text = [ControllersSettingsUtil getLocalizedStringForSIDevice:kSupportedPadDevices[indexPath.row]];
  } else {
    text = [ControllersSettingsUtil getLocalizedStringForWiimoteSource:kSupportedWiimoteSources[indexPath.row]];
  }
  
  cell.typeLabel.text = text;
  
  if (indexPath.row == _lastSelected) {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  } else {
    cell.accessoryType = UITableViewCellAccessoryNone;
  }
  
  return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  if (_lastSelected != indexPath.row) {
    if (self.portType == DOLControllerPortTypePad) {
      Config::SetBaseOrCurrent(Config::GetInfoForSIDevice(self.portNumber), kSupportedPadDevices[indexPath.row]);
    } else {
      Config::SetBaseOrCurrent(Config::GetInfoForWiimoteSource(self.portNumber), kSupportedWiimoteSources[indexPath.row]);
    }
    
    ControllersTypeCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    if (_lastSelected != -1) {
      ControllersTypeCell* oldCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_lastSelected inSection:0]];
      oldCell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    _lastSelected = indexPath.row;
  }
  
  [tableView deselectRowAtIndexPath:indexPath animated:true];
}

@end
