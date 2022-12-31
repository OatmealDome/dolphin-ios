// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "FirstRunInitializationService.h"

@implementation FirstRunInitializationService

- (BOOL)application:(UIApplication*)application willFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id>*)launchOptions {
  
  NSUserDefaults* userDefaults = NSUserDefaults.standardUserDefaults;
  
  NSURL* defaultsPath = [[NSBundle mainBundle] URLForResource:@"DefaultPreferences" withExtension:@"plist"];
  NSDictionary* defaultsDict = [NSDictionary dictionaryWithContentsOfURL:defaultsPath];
  [userDefaults registerDefaults:defaultsDict];
  
  NSInteger launchTimes = [userDefaults integerForKey:@"launch_times"];
  
  [userDefaults setInteger:launchTimes + 1 forKey:@"launch_times"];
  
  return true;
}

@end
