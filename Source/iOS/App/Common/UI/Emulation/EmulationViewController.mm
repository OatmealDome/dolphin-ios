// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "EmulationViewController.h"

#import "Common/WindowSystemInfo.h"

#import "Core/Boot/Boot.h"
#import "Core/BootManager.h"
#import "Core/Core.h"

#import "EmulationBootParameter.h"

@interface EmulationViewController ()

@end

@implementation EmulationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
  WindowSystemInfo wsi;
  wsi.type = WindowSystemType::iOS;
  wsi.render_surface = (__bridge void*)self.metalView.layer;
  wsi.render_surface_scale = UIScreen.mainScreen.scale;
  
  std::unique_ptr<BootParameters> boot = [self.bootParameter generateDolphinBootParameter];
  
  if (BootManager::BootCore(std::move(boot), wsi)) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      while (Core::GetState() == Core::State::Starting) {
        [NSThread sleepForTimeInterval:0.025];
      }
      
      while (Core::IsRunning()) {
        Core::HostDispatchJobs();
      }
    });
  }
}

@end
