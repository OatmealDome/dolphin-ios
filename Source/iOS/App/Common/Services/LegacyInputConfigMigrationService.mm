// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "LegacyInputConfigMigrationService.h"

#import "Common/FileUtil.h"
#import "Common/IniFile.h"

#import "Core/HW/GCPad.h"
#import "Core/HW/Wiimote.h"

#import "InputCommon/ControllerEmu/ControllerEmu.h"
#import "InputCommon/InputConfig.h"

@implementation LegacyInputConfigMigrationService

- (void)convertInputConfig:(InputConfig*)config {
  for (int i = 0; i < 4; i++) {
    ControllerEmu::EmulatedController* controller = config->GetController(i);
    
    const ciface::Core::DeviceQualifier& qualifier = controller->GetDefaultDevice();
    
    if (qualifier.source != "Android" || qualifier.name != "Touchscreen") {
      continue;
    }
    
    Common::IniFile iniFile;
    
    // We no longer support Touchscreen devices on ports other than the first one.
    // If this is not the first device, we will skip loading the INI file, which will cause
    // the code to import a blank profile.
    if (i == 0) {
      const std::string builtInPath = File::GetSysDirectory() + "Profiles/" + config->GetProfileDirectoryName() + "/Touchscreen.ini";
      
      iniFile.Load(builtInPath);
    }
    
    controller->LoadConfig(iniFile.GetOrCreateSection("Profile"));
    controller->UpdateReferences(g_controller_interface);
  }
  
  config->SaveConfig();
}

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id>*)launchOptions {
  [self convertInputConfig:Pad::GetConfig()];
  [self convertInputConfig:Wiimote::GetConfig()];
  
  return true;
}

@end
