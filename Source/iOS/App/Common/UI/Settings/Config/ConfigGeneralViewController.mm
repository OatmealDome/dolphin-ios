// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "ConfigGeneralViewController.h"

#import "Core/Config/MainSettings.h"

@interface ConfigGeneralViewController ()

@end

@implementation ConfigGeneralViewController

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  [self.dualCoreSwitch setOn:Config::Get(Config::MAIN_CPU_THREAD)];
  [self.dualCoreSwitch addValueChangedTarget:self action:@selector(dualCoreChanged)];
  
  [self.cheatsSwitch setOn:Config::Get(Config::MAIN_ENABLE_CHEATS)];
  [self.cheatsSwitch addValueChangedTarget:self action:@selector(cheatsChanged)];
  
  [self.mismatchedRegionSwitch setOn:Config::Get(Config::MAIN_OVERRIDE_REGION_SETTINGS)];
  [self.mismatchedRegionSwitch addValueChangedTarget:self action:@selector(mismatchedRegionChanged)];
  
  [self.changeDiscsSwitch setOn:Config::Get(Config::MAIN_AUTO_DISC_CHANGE)];
  [self.changeDiscsSwitch addValueChangedTarget:self action:@selector(changeDiscsChanged)];
  
  int speedLimit = Config::Get(Config::MAIN_EMULATION_SPEED) * 100;
  
  if (speedLimit == 0) {
    self.speedLimitLabel.text = @"Unlimited";
  } else {
    self.speedLimitLabel.text = [NSString stringWithFormat:@"%d%%", speedLimit];
  }
}

- (void)dualCoreChanged {
  Config::SetBaseOrCurrent(Config::MAIN_CPU_THREAD, [self.dualCoreSwitch isOn]);
}

- (void)cheatsChanged {
  Config::SetBaseOrCurrent(Config::MAIN_ENABLE_CHEATS, [self.cheatsSwitch isOn]);
}

- (void)mismatchedRegionChanged {
  Config::SetBaseOrCurrent(Config::MAIN_OVERRIDE_REGION_SETTINGS, [self.mismatchedRegionSwitch isOn]);
}

- (void)changeDiscsChanged {
  Config::SetBase(Config::MAIN_AUTO_DISC_CHANGE, [self.changeDiscsSwitch isOn]);
}

@end
