// Copyright 2024 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "LowPowerModeManager.h"

@implementation LowPowerModeManager

+ (instancetype)shared {
  static LowPowerModeManager* sharedInstance = nil;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });

  return sharedInstance;
}

- (instancetype)init {
  if (self = [super init]) {
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(handlePowerStateDidChangeNotification:)
     name:NSProcessInfoPowerStateDidChangeNotification
     object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)isLowPowerModeEnabled {
  return [[NSProcessInfo processInfo] isLowPowerModeEnabled];
}

- (void)handlePowerStateDidChangeNotification:(NSNotification *)notification {
  dispatch_async(dispatch_get_main_queue(), ^{
    self.lowPowerModeDidChangeHandler([self isLowPowerModeEnabled]);
  });
}

@end
