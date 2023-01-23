// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "AboutViewController.h"

@interface AboutViewController ()

@end

@implementation AboutViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  [self.scrollView flashScrollIndicators];
}

- (IBAction)sourceCodePressed:(id)sender {
  NSURL* url = [NSURL URLWithString:@"https://github.com/oatmealdome/dolphin-ios/"];
  [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

@end
