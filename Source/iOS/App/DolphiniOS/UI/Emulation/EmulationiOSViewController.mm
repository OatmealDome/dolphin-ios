// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "EmulationiOSViewController.h"

#import "Core/ConfigManager.h"

#import "HostNotifications.h"

@interface EmulationiOSViewController ()

@end

@implementation EmulationiOSViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveTitleChangedNotification) name:DOLHostTitleChangedNotification object:nil];
}

- (void)receiveTitleChangedNotification {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (SConfig::GetInstance().bWii) {
      // TODO
    } else {
      [self updateVisibleTouchPadToGameCube];
    }
  });
}

- (void)updateVisibleTouchPadToGameCube {
  if (self.gamecubePad.userInteractionEnabled) {
    return;
  }
  
  self.gamecubePad.userInteractionEnabled = true;
  
  [UIView animateWithDuration:0.5f animations:^{
    self.gamecubePad.alpha = 1.0;
  }];
}

@end
