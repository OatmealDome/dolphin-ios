// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "EmulationViewController.h"

#import "Core/Config/MainSettings.h"
#import "Core/Core.h"
#import "Core/Host.h"

#import "EmulationBootParameter.h"
#import "EmulationCoordinator.h"
#import "LocalizationUtil.h"
#import "JitManager.h"
#import "NKitWarningViewController.h"

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
  self.stopButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(stopPressed)];
  self.pauseButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(pausePressed)];
  self.playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playPressed)];
  
  self.navigationItem.rightBarButtonItems = @[
    self.stopButton,
    self.pauseButton
  ];
  
  [self.navigationController setNavigationBarHidden:true animated:true];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveEmulationEndNotification) name:DOLEmulationDidEndNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  if (!_didStartEmulation) {
    if (![JitManager shared].acquiredJit) {
      JitWaitViewController* jitController = [[JitWaitViewController alloc] initWithNibName:@"JitWait" bundle:nil];
      jitController.delegate = self;
      jitController.modalInPresentation = true;
      
      [self presentViewController:jitController animated:true completion:nil];
    } else if ([self checkIfNeedToShowNKitWarning]) {
      [self showNKitWarning];
    } else {
      [self startEmulation];
    }
    
    _didStartEmulation = true;
  }
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:DOLEmulationDidEndNotification object:nil];
}

- (void)didFinishJitScreenWithResult:(BOOL)result sender:(id)sender {
  [self dismissViewControllerAnimated:true completion:^{
    if (result) {
      if ([self checkIfNeedToShowNKitWarning]) {
        [self showNKitWarning];
      } else {
        [self startEmulation];
      }
    } else {
      [self.navigationController dismissViewControllerAnimated:true completion:nil];
    }
  }];
}

- (BOOL)checkIfNeedToShowNKitWarning {
  if (Config::GetBase(Config::MAIN_SKIP_NKIT_WARNING)) {
    return false;
  }
  
  return self.bootParameter.isNKit;
}

- (void)showNKitWarning {
  NKitWarningViewController* nkitController = [[NKitWarningViewController alloc] initWithNibName:@"NKitWarning" bundle:nil];
  nkitController.delegate = self;
  nkitController.modalInPresentation = true;
  
  [self presentViewController:nkitController animated:true completion:nil];
}

- (void)didFinishNKitWarningScreenWithResult:(BOOL)result sender:(id)sender {
  [self dismissViewControllerAnimated:true completion:^{
    if (result) {
      [self startEmulation];
    } else {
      [self.navigationController dismissViewControllerAnimated:true completion:nil];
    }
  }];
}

- (void)startEmulation {
  [[EmulationCoordinator shared] runEmulationWithBootParameter:self.bootParameter];
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

- (void)stopPressed {
  void (^stop)() = ^{
    Host_Message(HostMessageID::WMUserStop);
  };
  
  if (Config::Get(Config::MAIN_CONFIRM_ON_STOP)) {
  UIAlertController* alert = [UIAlertController alertControllerWithTitle:DOLCoreLocalizedString(@"Confirm") message:DOLCoreLocalizedString(@"Do you want to stop the current emulation?") preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"No") style:UIAlertActionStyleDefault handler:nil]];
    
    [alert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"Yes") style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action) {
      stop();
    }]];
    
    [self presentViewController:alert animated:true completion:nil];
  } else {
    stop();
  }
}

- (void)pausePressed {
  Core::SetState(Core::State::Paused);
  
  self.navigationItem.rightBarButtonItems = @[
    self.stopButton,
    self.playButton
  ];
}

- (void)playPressed {
  Core::SetState(Core::State::Running);
  
  self.navigationItem.rightBarButtonItems = @[
    self.stopButton,
    self.pauseButton
  ];
}

- (void)receiveEmulationEndNotification {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.navigationController dismissViewControllerAnimated:true completion:^{
      if (![EmulationCoordinator shared].isExternalDisplayConnected) {
        [[EmulationCoordinator shared] clearMetalLayer];
      }
    }];
  });
}

@end
