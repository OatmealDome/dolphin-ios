// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "UpdateRequiredNoticeViewController.h"

@interface UpdateRequiredNoticeViewController ()

@end

@implementation UpdateRequiredNoticeViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
}

- (IBAction)updateNowPressed:(id)sender {
  NSString* url = @"https://dolphinios.oatmealdome.me/update";
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url] options:@{} completionHandler:nil];
}

@end
