// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "ControllersRootViewController.h"

#import "Core/Config/MainSettings.h"
#import "Core/Config/WiimoteSettings.h"
#import "Core/HW/Wiimote.h"

#import "ControllersSettingsUtil.h"
#import "LocalizationUtil.h"
#import "MappingRootViewController.h"

@interface ControllersRootViewController ()

@end

@implementation ControllersRootViewController {
  DOLMappingType _targetType;
  int _targetPort;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  NSString* gamecubeString = DOLCoreLocalizedStringWithArgs(@"Port %1", @"d");
  NSString* wiiString = DOLCoreLocalizedStringWithArgs(@"Wii Remote %1", @"d");
  
  for (int i = 0; i < 4; i++) {
    //
    // GameCube
    //
    
    const SerialInterface::SIDevices siDevice = Config::Get(Config::GetInfoForSIDevice(i));
    
    ControllerPortCell* gamecubeCell = self.gamecubeCells[i];
    gamecubeCell.portLabel.text = [NSString stringWithFormat:gamecubeString, i + 1];
    gamecubeCell.typeLabel.text = [ControllersSettingsUtil getLocalizedStringForSIDevice:siDevice];
    
    //
    // Wii
    //
    
    WiimoteSource wiiSource = Config::Get(Config::GetInfoForWiimoteSource(i));
    
    ControllerPortCell* wiiCell = self.wiiCells[i];
    wiiCell.portLabel.text = [NSString stringWithFormat:wiiString, i + 1];
    wiiCell.typeLabel.text = [ControllersSettingsUtil getLocalizedStringForWiimoteSource:wiiSource];
  }
}

@end
