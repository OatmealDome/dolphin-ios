// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "UpdateNoticeViewController.h"

#import "Core/State.h"

@interface UpdateNoticeViewController ()

@end

@implementation UpdateNoticeViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  NSString* message = [NSString stringWithFormat:@"DolphiniOS version %@ is now available.", self.updateInfo[@"version"]];
  [self.versionLabel setText:message];
  
  [self.changesLabel setText:self.updateInfo[@"changes"]];
  
  [self.saveStateLabel setHidden:(NSInteger)self.updateInfo[@"state_version"] != State::GetVersion()];
}

- (IBAction)updateNowPressed:(id)sender {
  NSURL* url = [NSURL URLWithString:self.updateInfo[@"install_url"]];
  [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (IBAction)seeChangesPressed:(id)sender {
  NSURL* url = [NSURL URLWithString:self.updateInfo[@"changes_url"]];
  [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (IBAction)notNowPressed:(id)sender {
  [self.navigationController popViewControllerAnimated:true];
}


@end
