// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "DolphinCoreService.h"

#import "Core/Config/UISettings.h"
#import "Core/Config/MainSettings.h"
#import "Core/Config/GraphicsSettings.h"
#import "Core/Core.h"
#import "Core/HW/GCPad.h"
#import "Core/HW/Wiimote.h"
#import "Core/System.h"

#import "Common/MsgHandler.h"

#import "InputCommon/ControllerInterface/ControllerInterface.h"
#import "InputCommon/InputConfig.h"

#import "UICommon/UICommon.h"

#import "DolphiniOS-Swift.h"
#import "EmulationCoordinator.h"
#import "FastmemManager.h"
#import "FoundationStringUtil.h"
#import "HostQueue.h"
#import "LocalizationUtil.h"
#import "MsgAlertManager.h"

@implementation DolphinCoreService

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id>*)launchOptions {
  Core::DeclareAsHostThread();
  
  UICommon::SetUserDirectory(FoundationToCppString([UserFolderUtil getUserFolder]));
  UICommon::CreateDirectories();
  UICommon::Init();
  
  [[MsgAlertManager shared] registerHandler];
  
  Common::RegisterStringTranslator([](const char* text) {
    return FoundationToCppString(DOLCoreLocalizedString(CToFoundationString(text)));
  });
  
  Config::SetBase(Config::MAIN_USE_GAME_COVERS, true);
  
  const bool fastmemAvailable = [FastmemManager shared].fastmemAvailable;
  Config::SetBase(Config::MAIN_FASTMEM, fastmemAvailable);
  Config::SetBase(Config::MAIN_FASTMEM_ARENA, fastmemAvailable);
  
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
  DOLHostQueueRunSync(^{
    auto& system = Core::System::GetInstance();
    
    if (Core::IsRunning(system) && ![EmulationCoordinator shared].userRequestedPause) {
      Core::SetState(system, Core::State::Running);
    }
  });
}

- (void)applicationWillResignActive:(UIApplication*)application {
  DOLHostQueueRunSync(^{
    auto& system = Core::System::GetInstance();
    
    if (Core::IsRunning(system) && ![EmulationCoordinator shared].userRequestedPause) {
      Core::SetState(system, Core::State::Paused);
    }
    
    // Write out the configuration in case we don't get a chance later
    Config::Save();
  });
}

- (void)applicationWillTerminate:(UIApplication*)application {
  DOLHostQueueRunSync(^{
    auto& system = Core::System::GetInstance();
    
    if (Core::IsRunning(system)) {
      Core::Stop(Core::System::GetInstance());
      
      // Spin while Core stops
      while (Core::GetState(Core::System::GetInstance()) != Core::State::Uninitialized) {}
    }
    
    Pad::Shutdown();
    Wiimote::Shutdown();
    g_controller_interface.Shutdown();
    
    Config::Save();
    
    Core::Shutdown(system);
    UICommon::Shutdown();
  });
}

@end
