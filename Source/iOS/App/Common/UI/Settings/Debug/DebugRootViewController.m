// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "DebugRootViewController.h"

#import "VirtualMFiControllerManager.h"

@interface DebugRootViewController ()

@end

@implementation DebugRootViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.mfiSwitch.on = [VirtualMFiControllerManager shared].shouldConnectController;
  [self.mfiSwitch addValueChangedTarget:self action:@selector(mfiChanged)];
}

- (void)mfiChanged {
  [VirtualMFiControllerManager shared].shouldConnectController = self.mfiSwitch.on;
}

@end
