// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "ControllersRootViewController.h"

#import "Core/Config/MainSettings.h"
#import "Core/Config/WiimoteSettings.h"
#import "Core/HW/Wiimote.h"

#import "ControllersPortViewController.h"
#import "ControllersSettingsUtil.h"
#import "DOLControllerPortType.h"
#import "LocalizationUtil.h"

@interface ControllersRootViewController ()

@end

@implementation ControllersRootViewController {
  DOLControllerPortType _targetType;
  int _targetPort;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  NSString* gamecubeString = DOLCoreLocalizedStringWithArgs(@"Port %1", @"d");
  NSString* wiiString = DOLCoreLocalizedStringWithArgs(@"Wii Remote %1", @"d");
  
  for (int i = 0; i < 4; i++) {
    ControllersRootPortCell* gamecubeCell = self.gamecubeCells[i];
    gamecubeCell.portLabel.text = [NSString stringWithFormat:gamecubeString, i + 1];
    
    ControllersRootPortCell* wiiCell = self.wiiCells[i];
    wiiCell.portLabel.text = [NSString stringWithFormat:wiiString, i + 1];
  }
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  for (int i = 0; i < 4; i++) {
    const SerialInterface::SIDevices siDevice = Config::Get(Config::GetInfoForSIDevice(i));
    
    ControllersRootPortCell* gamecubeCell = self.gamecubeCells[i];
    gamecubeCell.typeLabel.text = [ControllersSettingsUtil getLocalizedStringForSIDevice:siDevice];
    
    WiimoteSource wiiSource = Config::Get(Config::GetInfoForWiimoteSource(i));
    
    ControllersRootPortCell* wiiCell = self.wiiCells[i];
    wiiCell.typeLabel.text = [ControllersSettingsUtil getLocalizedStringForWiimoteSource:wiiSource];
  }
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  if (indexPath.section == 0) {
    _targetType = DOLControllerPortTypePad;
  } else if (indexPath.section == 1) {
    _targetType = DOLControllerPortTypeWiimote;
  } else {
    // The storyboard will handle any segues.
    return;
  }
  
  _targetType = indexPath.section == 0 ? DOLControllerPortTypePad : DOLControllerPortTypeWiimote;
  _targetPort = (int)indexPath.row;
  
  [self performSegueWithIdentifier:@"toPort" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
  if ([segue.identifier isEqualToString:@"toPort"]) {
    ControllersPortViewController* portController = segue.destinationViewController;
    
    portController.portType = _targetType;
    portController.portNumber = _targetPort;
  }
}

@end
