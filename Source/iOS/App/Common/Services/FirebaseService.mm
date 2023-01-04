// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "FirebaseService.h"

#import <FirebaseCore/FirebaseCore.h>

#import "Swift.h"

@implementation FirebaseService

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id>*)launchOptions {
  if ([VersionManager shared].buildSource != DOLBuildSourceOfficial) {
    return true;
  }
  
  [FIRApp configure];
  
  return true;
}

@end
