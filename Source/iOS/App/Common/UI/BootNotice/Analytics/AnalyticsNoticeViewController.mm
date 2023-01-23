// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "AnalyticsNoticeViewController.h"

#import <FirebaseAnalytics/FirebaseAnalytics.h>
#import <FirebaseCrashlytics/FirebaseCrashlytics.h>

#import "Core/Config/MainSettings.h"

@interface AnalyticsNoticeViewController ()

@end

@implementation AnalyticsNoticeViewController

- (void)viewDidLoad {
  [super viewDidLoad];
}

- (void)HandleResponse:(bool)response {
  Config::SetBaseOrCurrent(Config::MAIN_ANALYTICS_PERMISSION_ASKED, true);
  Config::SetBaseOrCurrent(Config::MAIN_ANALYTICS_ENABLED, response);
  
  [FIRAnalytics setAnalyticsCollectionEnabled:response];
  [[FIRCrashlytics crashlytics] setCrashlyticsCollectionEnabled:response];
  
  [self.navigationController popViewControllerAnimated:true];
  
  [self.delegate didFinishAnalyticsNoticeWithResult:response sender:self];
}

- (IBAction)optInPressed:(id)sender {
  [self HandleResponse:true];
}

- (IBAction)optOutPressed:(id)sender {
  [self HandleResponse:false];
}

@end
