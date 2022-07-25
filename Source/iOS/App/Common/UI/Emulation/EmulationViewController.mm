// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "EmulationViewController.h"

#import "Core/Core.h"

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
  
  // Create right bar button items
  self.pauseButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(pausePressed)];
  self.playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playPressed)];
  
  self.navigationItem.rightBarButtonItems = @[
    self.pauseButton
  ];
  
  [self.navigationController setNavigationBarHidden:true animated:true];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  if (!_didStartEmulation) {
    [[EmulationCoordinator shared] runEmulationWithBootParameter:self.bootParameter];
    
    _didStartEmulation = true;
  }
}

- (void)updateNavigationBar:(bool)hidden {
  [self.navigationController setNavigationBarHidden:hidden animated:true];
  
  [self setNeedsStatusBarAppearanceUpdate];
  
  // Adjust the safe area insets.
  UIEdgeInsets insets = self.additionalSafeAreaInsets;
  if (hidden) {
    insets.top = 0;
  } else {
    // The safe area should extend behind the navigation bar.
    // This makes the bar "float" on top of the content.
    insets.top = -(self.navigationController.navigationBar.bounds.size.height);
  }
  
  self.additionalSafeAreaInsets = insets;
}

- (void)pausePressed {
  Core::SetState(Core::State::Paused);
  
  self.navigationItem.rightBarButtonItems = @[
    self.playButton
  ];
}

- (void)playPressed {
  Core::SetState(Core::State::Running);
  
  self.navigationItem.rightBarButtonItems = @[
    self.pauseButton
  ];
}

@end
