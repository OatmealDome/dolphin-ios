// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "GraphicsRootViewController.h"

#import "VideoCommon/VideoBackendBase.h"

@interface GraphicsRootViewController ()

@end

@implementation GraphicsRootViewController

- (void)viewDidLoad {
  VideoBackendBase::PopulateBackendInfoFromUI();
}

@end
