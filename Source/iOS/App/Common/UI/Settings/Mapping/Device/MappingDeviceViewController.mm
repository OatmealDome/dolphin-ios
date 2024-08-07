// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "MappingDeviceViewController.h"

#import <string>
#import <vector>

#import "Common/FileUtil.h"

#import "InputCommon/ControllerEmu/ControllerEmu.h"
#import "InputCommon/ControllerInterface/ControllerInterface.h"
#import "InputCommon/InputConfig.h"

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
  
  g_controller_interface.RefreshDevices();
  
  for (const auto& name : g_controller_interface.GetAllDeviceStrings()) {
    if (self.filterType != DOLDeviceFilterNone) {
      ciface::Core::DeviceQualifier qualifier;
      qualifier.FromString(name);
      
      if (qualifier.source == "iOS" && qualifier.name == "Touchscreen") {
        // Don't list unnecessary Touchscreen devices depending on the filter type.
        if ((self.filterType == DOLDeviceFilterTouchscreenExceptPad && qualifier.cid != 0)
            || (self.filterType == DOLDeviceFilterTouchscreenExceptWii && qualifier.cid != 4)
            || self.filterType == DOLDeviceFilterTouchscreenAll) {
          continue;
        }
      }
    }
    
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
    const std::string device = _devices[indexPath.row];
    
    ciface::Core::DeviceQualifier qualifier;
    qualifier.FromString(device);
    
    self.emulatedController->SetDefaultDevice(device);
    self.emulatedController->UpdateReferences(g_controller_interface);
    
    MappingDeviceCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    if (_lastSelected != -1) {
      MappingDeviceCell* oldCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_lastSelected inSection:0]];
      oldCell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    _lastSelected = indexPath.row;
    
    bool isTouchscreen = qualifier.source == "iOS";
    bool isMFiPhysicalController = qualifier.source == "MFi" && qualifier.name != "Keyboard";
    
    if (isTouchscreen || isMFiPhysicalController) {
      UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Load Defaults" message:@"Would you like to load the default profile for this device type?\n\nWARNING: If you choose to proceed, your current configuration will be overwritten." preferredStyle:UIAlertControllerStyleAlert];
      
      [alertController addAction:[UIAlertAction actionWithTitle:@"Load" style:UIAlertActionStyleDestructive handler:^(UIAlertAction*) {
        std::string iniName;
        
        if (isTouchscreen) {
          iniName = "Touchscreen";
        } else {
          iniName = "Physical Controller";
        }
        
        const std::string profilePath = File::GetSysDirectory() + "Profiles/" + self.inputConfig->GetProfileDirectoryName() + "/" + iniName + ".ini";
        
        Common::IniFile iniFile;
        iniFile.Load(profilePath);
        
        self.emulatedController->LoadConfig(iniFile.GetOrCreateSection("Profile"));
        self.emulatedController->SetDefaultDevice(device);
        self.emulatedController->UpdateReferences(g_controller_interface);
      }]];
      
      [alertController addAction:[UIAlertAction actionWithTitle:@"Don't Load" style:UIAlertActionStyleCancel handler:nil]];
      
      [self presentViewController:alertController animated:true completion:nil];
    }
    
    [self.delegate deviceDidChange:self];
  }
  
  [tableView deselectRowAtIndexPath:indexPath animated:true];
}

@end
