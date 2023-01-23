// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "DolphinCoreService.h"

#import "Core/Config/UISettings.h"
#import "Core/Config/MainSettings.h"
#import "Core/Config/GraphicsSettings.h"
#import "Core/Core.h"
#import "Core/HW/GCPad.h"
#import "Core/HW/Wiimote.h"

#import "Common/MsgHandler.h"

#import "InputCommon/ControllerInterface/ControllerInterface.h"
#import "InputCommon/InputConfig.h"

#import "UICommon/UICommon.h"

#import "DolphiniOS-Swift.h"
#import "EmulationCoordinator.h"
#import "FoundationStringUtil.h"
#import "LocalizationUtil.h"
#import "FastmemManager.h"
#import "MsgAlertManager.h"

@implementation DolphinCoreService

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id>*)launchOptions {
  UICommon::SetUserDirectory(FoundationToCppString([UserFolderUtil getUserFolder]));
  UICommon::CreateDirectories();
  UICommon::Init();
  
  [[MsgAlertManager shared] registerHandler];
  
  Common::RegisterStringTranslator([](const char* text) {
    return FoundationToCppString(DOLCoreLocalizedString(CToFoundationString(text)));
  });
  
  Config::SetBase(Config::MAIN_USE_GAME_COVERS, true);
  
  Config::SetBase(Config::MAIN_FASTMEM, [FastmemManager shared].fastmemAvailable);
  
  WindowSystemInfo wsi;
  wsi.type = WindowSystemType::iOS;
  
  g_controller_interface.Initialize(wsi);
  
  Pad::Initialize();
  Wiimote::Initialize(Wiimote::InitializeMode::DO_NOT_WAIT_FOR_WIIMOTES);
  
  Wiimote::LoadConfig();
  Wiimote::GetConfig()->SaveConfig();

  Pad::LoadConfig();
  Pad::GetConfig()->SaveConfig();

  return YES;
}

- (void)applicationDidBecomeActive:(UIApplication*)application {
  if (Core::IsRunning() && ![EmulationCoordinator shared].userRequestedPause) {
    Core::SetState(Core::State::Running);
  }
}

- (void)applicationWillResignActive:(UIApplication*)application {
  if (Core::IsRunning() && ![EmulationCoordinator shared].userRequestedPause) {
    Core::SetState(Core::State::Paused);
  }
  
  // Write out the configuration in case we don't get a chance later
  Config::Save();
}

@end
