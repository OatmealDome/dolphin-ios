// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "BootNoticeNavigationViewController.h"

@interface BootNoticeNavigationViewController ()

@end

@implementation BootNoticeNavigationViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
}

- (UIViewController*)popViewControllerAnimated:(BOOL)animated {
  // Dismiss ourselves if we are popping the last view controller.
  if (self.viewControllers.count == 1) {
    [self dismissViewControllerAnimated:true completion:nil];
  }
  
  return [super popViewControllerAnimated:animated];
}

@end
