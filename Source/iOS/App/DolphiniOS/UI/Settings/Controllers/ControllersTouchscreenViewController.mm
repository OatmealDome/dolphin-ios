// Copyright 2024 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "ControllersTouchscreenViewController.h"

#import "Core/Config/iOSSettings.h"

@interface ControllersTouchscreenViewController ()

@end

@implementation ControllersTouchscreenViewController

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  self.opacitySlider.value = Config::Get(Config::MAIN_TOUCH_PAD_OPACITY);
}

- (IBAction)opacitySliderChanged:(id)sender {
  Config::SetBaseOrCurrent(Config::MAIN_TOUCH_PAD_OPACITY, self.opacitySlider.value);
}

@end
