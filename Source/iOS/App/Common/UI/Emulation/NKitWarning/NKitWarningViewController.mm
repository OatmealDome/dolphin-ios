// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "NKitWarningViewController.h"

#import "Core/Config/MainSettings.h"

#import "Swift.h"

@interface NKitWarningViewController ()

@end

@implementation NKitWarningViewController

- (IBAction)cancelPressed:(id)sender {
  [self.delegate didFinishNKitWarningScreenWithResult:false sender:self];
}

- (IBAction)continuePressed:(id)sender {
  Config::SetBase(Config::MAIN_SKIP_NKIT_WARNING, self.showSwitch.on);
  
  [self.delegate didFinishNKitWarningScreenWithResult:true sender:self];
}

@end
