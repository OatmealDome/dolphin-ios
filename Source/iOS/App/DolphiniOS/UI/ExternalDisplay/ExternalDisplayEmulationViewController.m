// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "ExternalDisplayEmulationViewController.h"

#import "EmulationCoordinator.h"

@interface ExternalDisplayEmulationViewController ()

@end

@implementation ExternalDisplayEmulationViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [[EmulationCoordinator shared] registerExternalDisplayView:self.view];
}

@end
