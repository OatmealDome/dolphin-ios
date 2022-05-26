// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "EmulationViewController.h"

#import "Common/WindowSystemInfo.h"

#import "Core/Boot/Boot.h"
#import "Core/BootManager.h"
#import "Core/Core.h"

#import "EmulationBootParameter.h"

@interface EmulationViewController ()

- (void)runEmulation;

@end

@implementation EmulationViewController

- (void)viewDidLoad {
  [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [self runEmulation];
  });
}

- (void)runEmulation {
  __block WindowSystemInfo wsi;
  wsi.type = WindowSystemType::iOS;
  
  dispatch_sync(dispatch_get_main_queue(), ^{
    wsi.render_surface = (__bridge void*)self.metalView.layer;
  });
  
  wsi.render_surface_scale = UIScreen.mainScreen.scale;
  
  std::unique_ptr<BootParameters> boot = [self.bootParameter generateDolphinBootParameter];
  
  if (!BootManager::BootCore(std::move(boot), wsi)) {
    PanicAlertFmt("Failed to init core!");
    return;
  }
  
  while (Core::GetState() == Core::State::Starting) {
    [NSThread sleepForTimeInterval:0.025];
  }
  
  while (Core::IsRunning()) {
    Core::HostDispatchJobs();
  }
}

@end
