// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "ControllersRootViewController.h"

#import "Core/Config/MainSettings.h"
#import "Core/Config/WiimoteSettings.h"
#import "Core/HW/SI/SI_Device.h"
#import "Core/HW/Wiimote.h"

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
    
    NSString* gamecubeType;
    switch (siDevice) {
      case SerialInterface::SIDEVICE_NONE:
        gamecubeType = @"None";
        break;
      case SerialInterface::SIDEVICE_GC_CONTROLLER:
        gamecubeType = @"Standard Controller";
        break;
      case SerialInterface::SIDEVICE_WIIU_ADAPTER:
        gamecubeType = @"GameCube Adapter for Wii U";
        break;
      case SerialInterface::SIDEVICE_GC_STEERING:
        gamecubeType = @"Steering Wheel";
        break;
      case SerialInterface::SIDEVICE_DANCEMAT:
        gamecubeType = @"Dance Mat";
        break;
      case SerialInterface::SIDEVICE_GC_TARUKONGA:
        gamecubeType = @"DK Bongos";;
        break;
      case SerialInterface::SIDEVICE_GC_GBA_EMULATED:
        gamecubeType = @"GBA (Integrated)";
        break;
      case SerialInterface::SIDEVICE_GC_GBA:
        gamecubeType = @"GBA (TCP)";
        break;
      case SerialInterface::SIDEVICE_GC_KEYBOARD:
        gamecubeType = @"Keyboard";
        break;
      default:
        gamecubeType = @"Error";
        break;
    }
    
    ControllerPortCell* gamecubeCell = self.gamecubeCells[i];
    gamecubeCell.portLabel.text = [NSString stringWithFormat:gamecubeString, i + 1];
    gamecubeCell.typeLabel.text = DOLCoreLocalizedString(gamecubeType);
    
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
