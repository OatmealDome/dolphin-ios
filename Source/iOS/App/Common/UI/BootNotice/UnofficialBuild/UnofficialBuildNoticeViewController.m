// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "UnofficialBuildNoticeViewController.h"

@interface UnofficialBuildNoticeViewController ()

@end

@implementation UnofficialBuildNoticeViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
}

- (IBAction)okPressed:(id)sender {
  [self.navigationController popViewControllerAnimated:true];
}

@end
