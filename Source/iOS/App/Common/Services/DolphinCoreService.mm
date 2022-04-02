// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "DolphinCoreService.h"

#import "DolphiniOS-Swift.h"

#import "FoundationStringUtil.h"

#import "UICommon/UICommon.h"
#import "Core/Config/UISettings.h"


@implementation DolphinCoreService

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id>*)launchOptions {
  UICommon::SetUserDirectory(FoundationToCppString([UserFolderUtil getUserFolder]));
  UICommon::CreateDirectories();
  UICommon::Init();
  
  Config::SetBase(Config::MAIN_USE_GAME_COVERS, true);
  
  return YES;
}

@end
