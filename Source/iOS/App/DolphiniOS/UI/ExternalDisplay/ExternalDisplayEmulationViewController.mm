// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "ExternalDisplayEmulationViewController.h"

#import "Core/Core.h"
#import "Core/System.h"

#import "EmulationCoordinator.h"

@interface ExternalDisplayEmulationViewController ()

@end

@implementation ExternalDisplayEmulationViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [[EmulationCoordinator shared] registerExternalDisplayView:self.rendererView];
  
  if (Core::IsRunning(Core::System::GetInstance())) {
    self.rendererView.alpha = 1.0f;
    self.waitView.alpha = 0.0f;
  }
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveEmulationStartNotification) name:DOLEmulationDidStartNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveEmulationEndNotification) name:DOLEmulationDidEndNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:DOLEmulationDidStartNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:DOLEmulationDidEndNotification object:nil];
}

- (void)receiveEmulationStartNotification {
  dispatch_async(dispatch_get_main_queue(), ^{
    [UIView animateWithDuration:1.0f animations:^{
      self.rendererView.alpha = 1.0f;
      self.waitView.alpha = 0.0f;
    }];
  });
}

- (void)receiveEmulationEndNotification {
  dispatch_async(dispatch_get_main_queue(), ^{
    [UIView animateWithDuration:1.0f animations:^{
      self.rendererView.alpha = 0.0f;
      self.waitView.alpha = 1.0f;
    } completion:^(bool) {
      [[EmulationCoordinator shared] clearMetalLayer];
    }];
  });
}

@end
