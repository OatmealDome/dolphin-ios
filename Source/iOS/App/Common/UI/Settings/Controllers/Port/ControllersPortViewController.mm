// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "ControllersPortViewController.h"

#import "Core/Config/MainSettings.h"
#import "Core/Config/WiimoteSettings.h"

#import "ControllersSettingsUtil.h"
#import "ControllersTypeViewController.h"
#import "LocalizationUtil.h"

@interface ControllersPortViewController ()

@end

@implementation ControllersPortViewController {
  bool _configureEnabled;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  NSString* titleFormat;
  if (self.portType == DOLControllerPortTypePad) {
    // The string DolphinQt uses, "GameCube Controller at Port %1", is a bit too unwieldy for a UINavigationItem title.
    titleFormat = DOLCoreLocalizedStringWithArgs(@"Port %1", @"d");
  } else {
    titleFormat = DOLCoreLocalizedStringWithArgs(@"Wii Remote %1", @"d");
  }
  
  self.navigationItem.title = [NSString stringWithFormat:titleFormat, self.portNumber + 1];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  NSString* typeString;
  
  if (self.portType == DOLControllerPortTypePad) {
    const SerialInterface::SIDevices siDevice = Config::Get(Config::GetInfoForSIDevice(self.portNumber));
    
    typeString = [ControllersSettingsUtil getLocalizedStringForSIDevice:siDevice];
    _configureEnabled = siDevice != SerialInterface::SIDEVICE_NONE;
  } else {
    const WiimoteSource wiiSource = Config::Get(Config::GetInfoForWiimoteSource(self.portNumber));
    
    typeString = [ControllersSettingsUtil getLocalizedStringForWiimoteSource:wiiSource];
    _configureEnabled = wiiSource != WiimoteSource::None;
  }
  
  self.typeLabel.text = typeString;
  
  if (_configureEnabled) {
    self.configureLabel.textColor = [UIColor labelColor];
    self.configureCell.selectionStyle = UITableViewCellSelectionStyleDefault;
  } else {
    self.configureLabel.textColor = [UIColor systemGrayColor];
    self.configureCell.selectionStyle = UITableViewCellSelectionStyleNone;
  }
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
  if ([segue.identifier isEqualToString:@"toType"]) {
    ControllersTypeViewController* typeController = segue.destinationViewController;
    
    typeController.portType = self.portType;
    typeController.portNumber = self.portNumber;
  }
}

@end
