// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "FirebaseService.h"

#import <FirebaseAnalytics/FirebaseAnalytics.h>
#import <FirebaseCore/FirebaseCore.h>
#import <FirebaseCrashlytics/FirebaseCrashlytics.h>

#import "Core/Config/MainSettings.h"

#import "AnalyticsNoticeViewController.h"
#import "BootNoticeManager.h"
#import "Swift.h"

@interface FirebaseService () <AnalyticsNoticeViewControllerDelegate>

@end

@implementation FirebaseService {
  BOOL _shouldSendInitialEvent;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id>*)launchOptions {
  if ([VersionManager shared].appVersion.source != DOLBuildSourceOfficial) {
    return true;
  }
  
  [FIRApp configure];
  
  bool analyticsEnabled;
  
  if (!Config::GetBase(Config::MAIN_ANALYTICS_PERMISSION_ASKED)) {
    // Default to no analytics temporarily
    analyticsEnabled = false;
    
    AnalyticsNoticeViewController* controller = [[AnalyticsNoticeViewController alloc] initWithNibName:@"AnalyticsNotice" bundle:nil];
    controller.delegate = self;
    
    [[BootNoticeManager shared] enqueueViewController:controller];
  } else {
    analyticsEnabled = Config::GetBase(Config::MAIN_ANALYTICS_ENABLED);
  }
  
  [FIRAnalytics setAnalyticsCollectionEnabled:analyticsEnabled];
  [[FIRCrashlytics crashlytics] setCrashlyticsCollectionEnabled:analyticsEnabled];
  
  if (analyticsEnabled) {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    NSString* lastVersion = [defaults stringForKey:@"last_version"];
    NSString* currentVersion = [VersionManager shared].appVersion.userFacing;
    
    _shouldSendInitialEvent = ![lastVersion isEqualToString:currentVersion];
  } else {
    _shouldSendInitialEvent = false;
  }
  
  return true;
}

- (void)didFinishAnalyticsNoticeWithResult:(BOOL)result sender:(id)sender {
  if (result) {
    [self sendInitialAnalyticsEvents];
  }
}

- (void)sendInitialAnalyticsEvents {
  if (_shouldSendInitialEvent) {
    NSString* appType;
#ifdef NONJAILBROKEN
    appType = @"non-jailbroken";
#elif defined(TROLLSTORE)
    appType = @"trollstore";
#else
    appType = @"jailbroken";
#endif
    
    [FIRAnalytics logEventWithName:@"version_start" parameters:@{
      @"type" : appType,
      @"version" : [VersionManager shared].appVersion.userFacing
    }];
  }
}

@end
