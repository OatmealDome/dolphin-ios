// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "DolphinCoreService.h"

#import "Core/Config/UISettings.h"
#import "Core/Config/MainSettings.h"
#import "Core/Config/GraphicsSettings.h"
#import "Core/Core.h"
#import "Core/DolphinAnalytics.h"
#import "Core/HW/GCPad.h"
#import "Core/HW/Wiimote.h"
#import "Core/System.h"

#import "Common/FileUtil.h"
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

#ifdef DEBUG
  NSURL* loggerIniPath = [[NSBundle mainBundle] URLForResource:@"Logger" withExtension:@"ini"];
  std::string loggerIniCppPath = FoundationToCppString([loggerIniPath path]);
  std::string destPath = File::GetUserPath(F_LOGGERCONFIG_IDX);
  
  File::Delete(File::GetUserPath(F_LOGGERCONFIG_IDX));
  File::Copy(loggerIniCppPath, File::GetUserPath(F_LOGGERCONFIG_IDX));
#endif
  
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
  
  UICommon::InitControllers(wsi);
  
  // This technically doesn't send any reports since we disabled analytics...
  // However, it initializes DolphinAnalytics, which we need to do before starting any Wii games.
  DolphinAnalytics::Instance().ReportDolphinStart("ios");

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
    
    Config::Save();
    
    Core::Shutdown(system);
    
    UICommon::ShutdownControllers();
    UICommon::Shutdown();
  });
}

@end
