// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "DolphinCoreService.h"

#import "DolphiniOS-Swift.h"

#import "FoundationStringUtil.h"

#import <UICommon/UICommon.h>

@implementation DolphinCoreService

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id>*)launchOptions {
  NSString* userFolder = [UserFolderUtil getUserFolder];
  [[NSFileManager defaultManager] createDirectoryAtPath:userFolder withIntermediateDirectories:true attributes:nil error:nil];
  
  UICommon::SetUserDirectory(FoundationToCppString(userFolder));
  UICommon::Init();
  
  return YES;
}

@end
