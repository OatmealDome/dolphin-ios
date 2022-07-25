// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "EmulationViewController.h"

#import "EmulationCoordinator.h"

@interface EmulationViewController ()

@end

@implementation EmulationViewController {
  bool _didStartEmulation;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  _didStartEmulation = false;
  
  [[EmulationCoordinator shared] registerMainDisplayView:self.rendererView];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  if (!_didStartEmulation) {
    [[EmulationCoordinator shared] runEmulationWithBootParameter:self.bootParameter];
    
    _didStartEmulation = true;
  }
}

@end
