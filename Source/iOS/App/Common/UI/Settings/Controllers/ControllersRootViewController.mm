// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "ControllersRootViewController.h"

#import "Core/Config/MainSettings.h"
#import "Core/Config/WiimoteSettings.h"
#import "Core/HW/Wiimote.h"

#import "ControllersSettingsUtil.h"
#import "LocalizationUtil.h"

@interface ControllersRootViewController ()

@end

@implementation ControllersRootViewController

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
    
    NSString* wiiType;
    switch (Config::Get(Config::GetInfoForWiimoteSource(i))) {
      case WiimoteSource::None:
        wiiType = @"None";
        break;
      case WiimoteSource::Emulated:
        wiiType = @"Emulated Wii Remote";
        break;
      case WiimoteSource::Real:
        wiiType = @"Real Wii Remote";
        break;
      default:
        wiiType = @"Error";
        break;
    }
    
    ControllerPortCell* wiiCell = self.wiiCells[i];
    wiiCell.portLabel.text = [NSString stringWithFormat:wiiString, i + 1];
    wiiCell.typeLabel.text = DOLCoreLocalizedString(wiiType);
  }
}

@end
