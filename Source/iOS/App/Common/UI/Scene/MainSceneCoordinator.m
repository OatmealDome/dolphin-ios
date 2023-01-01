// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "MainSceneCoordinator.h"

@implementation MainSceneCoordinator

+ (MainSceneCoordinator*)shared {
  static MainSceneCoordinator* sharedInstance = nil;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });

  return sharedInstance;
}

@end
