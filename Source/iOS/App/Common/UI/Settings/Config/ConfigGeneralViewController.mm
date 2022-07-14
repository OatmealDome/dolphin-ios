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
}

- (void)dualCoreChanged {
  Config::SetCurrent(Config::MAIN_CPU_THREAD, [self.dualCoreSwitch isOn]);
}

- (void)cheatsChanged {
  Config::SetCurrent(Config::MAIN_ENABLE_CHEATS, [self.cheatsSwitch isOn]);
}

- (void)mismatchedRegionChanged {
  Config::SetCurrent(Config::MAIN_OVERRIDE_REGION_SETTINGS, [self.mismatchedRegionSwitch isOn]);
}

- (void)changeDiscsChanged {
  Config::SetCurrent(Config::MAIN_AUTO_DISC_CHANGE, [self.changeDiscsSwitch isOn]);
}

@end
