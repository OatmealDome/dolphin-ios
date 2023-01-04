// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "FirebaseService.h"

#import <FirebaseAnalytics/FirebaseAnalytics.h>
#import <FirebaseCore/FirebaseCore.h>
#import <FirebaseCrashlytics/FirebaseCrashlytics.h>

#import "Core/Config/MainSettings.h"

#import "BootNoticeManager.h"
#import "Swift.h"
#import "AnalyticsNoticeViewController.h"

@implementation FirebaseService

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id>*)launchOptions {
  if ([VersionManager shared].buildSource != DOLBuildSourceOfficial) {
    return true;
  }
  
  [FIRApp configure];
  
  bool analyticsEnabled;
  
  if (!Config::GetBase(Config::MAIN_ANALYTICS_PERMISSION_ASKED)) {
    // Default to no analytics temporarily
    analyticsEnabled = false;
    
    AnalyticsNoticeViewController* controller = [[AnalyticsNoticeViewController alloc] initWithNibName:@"AnalyticsNotice" bundle:nil];
    [[BootNoticeManager shared] enqueueViewController:controller];
  } else {
    analyticsEnabled = Config::GetBase(Config::MAIN_ANALYTICS_ENABLED);
  }
  
  [FIRAnalytics setAnalyticsCollectionEnabled:analyticsEnabled];
  [[FIRCrashlytics crashlytics] setCrashlyticsCollectionEnabled:analyticsEnabled];
  
  return true;
}

@end
