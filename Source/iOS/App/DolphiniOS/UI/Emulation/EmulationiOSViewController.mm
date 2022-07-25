// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "EmulationiOSViewController.h"

#import "Core/ConfigManager.h"
#import "Core/Config/MainSettings.h"
#import "Core/Config/WiimoteSettings.h"
#import "Core/HW/GCPad.h"
#import "Core/HW/SI/SI_Device.h"
#import "Core/HW/Wiimote.h"
#import "Core/HW/WiimoteEmu/WiimoteEmu.h"

#import "InputCommon/InputConfig.h"

#import "VideoCommon/RenderBase.h"

#import "HostNotifications.h"

typedef NS_ENUM(NSInteger, DOLEmulationVisibleTouchPad) {
  DOLEmulationVisibleTouchPadNone,
  DOLEmulationVisibleTouchPadGameCube,
  DOLEmulationVisibleTouchPadWiimote,
  DOLEmulationVisibleTouchPadSidewaysWiimote,
  DOLEmulationVisibleTouchPadClassic
};

@interface EmulationiOSViewController ()

@end

@implementation EmulationiOSViewController {
  DOLEmulationVisibleTouchPad _visibleTouchPad;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveTitleChangedNotification) name:DOLHostTitleChangedNotification object:nil];
}

- (void)viewDidLayoutSubviews {
  if (g_renderer) {
    g_renderer->ResizeSurface();
  }
}

- (void)receiveTitleChangedNotification {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (SConfig::GetInstance().bWii) {
      [self updateVisibleTouchPadToWii];
    } else {
      [self updateVisibleTouchPadToGameCube];
    }
  });
}

- (void)updateVisibleTouchPadToWii {
  DOLEmulationVisibleTouchPad targetTouchPad;
  
  if (Config::Get(Config::GetInfoForWiimoteSource(0)) != WiimoteSource::Emulated) {
    // No Wiimote is attached to this port. Fallback to GameCube if possible.
    [self updateVisibleTouchPadToGameCube];
    
    return;
  }
  
  const auto wiimote = static_cast<WiimoteEmu::Wiimote*>(Wiimote::GetConfig()->GetController(0));
  
  if (wiimote->GetDefaultDevice().source != "iOS") {
    // A real controller is mapped to this port. Fallback to GameCube in case port 1 is bound to the touchscreen.
    [self updateVisibleTouchPadToGameCube];
    
    return;
  }
  
  if (wiimote->GetActiveExtensionNumber() == WiimoteEmu::ExtensionNumber::CLASSIC) {
    targetTouchPad = DOLEmulationVisibleTouchPadClassic;
  } else if (wiimote->IsSideways()) {
    targetTouchPad = DOLEmulationVisibleTouchPadSidewaysWiimote;
  } else {
    targetTouchPad = DOLEmulationVisibleTouchPadWiimote;
  }
  
  [self updateVisibleTouchPadWithType:targetTouchPad];
}

- (void)updateVisibleTouchPadToGameCube {
  if (Config::Get(Config::GetInfoForSIDevice(0)) == SerialInterface::SIDEVICE_NONE) {
    // Nothing is plugged in to this port.
    return;
  }
  
  const auto device = Pad::GetConfig()->GetController(0);
  
  if (device->GetDefaultDevice().source != "iOS") {
    // A real controller is mapped to this port.
    return;
  }
  
  [self updateVisibleTouchPadWithType:DOLEmulationVisibleTouchPadGameCube];
}

- (void)updateVisibleTouchPadWithType:(DOLEmulationVisibleTouchPad)touchPad {
  if (_visibleTouchPad == touchPad) {
    return;
  }
  
  NSInteger targetIdx = touchPad - 1;
  
  for (int i = 0; i < [self.touchPads count]; i++) {
    TCView* padView = self.touchPads[i];
    padView.userInteractionEnabled = i == targetIdx;
  }
  
  [UIView animateWithDuration:0.5f animations:^{
    for (int i = 0; i < [self.touchPads count]; i++) {
      TCView* padView = self.touchPads[i];
      padView.alpha = i == targetIdx ? 1.0f : 0.0f;
    }
  }];
}

- (IBAction)pullDownPressed:(id)sender {
  [self updateNavigationBar:false];
  
  // Automatic hide after 5 seconds
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [self updateNavigationBar:true];
  });
}

@end
