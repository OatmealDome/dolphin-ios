// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "ConfigGameCubeViewController.h"

#import "Common/CommonPaths.h"
#import "Common/FileUtil.h"

#import "Core/Config/MainSettings.h"

#import "LocalizationUtil.h"

@interface ConfigGameCubeViewController ()

@end

@implementation ConfigGameCubeViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.mainMenuSwitch.on = Config::Get(Config::MAIN_SKIP_IPL);
  [self.mainMenuSwitch addValueChangedTarget:self action:@selector(mainMenuChanged)];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  bool haveMenu = false;
  for (const std::string dir : {USA_DIR, JAP_DIR, EUR_DIR}) {
    const auto path = DIR_SEP + dir + DIR_SEP GC_IPL;
    if (File::Exists(File::GetUserPath(D_GCUSER_IDX) + path) ||
        File::Exists(File::GetSysDirectory() + GC_SYS_DIR + path)) {
      haveMenu = true;
      break;
    }
  }
  
  self.mainMenuSwitch.enabled = haveMenu;
  
  NSString* language;
  switch (Config::Get(Config::MAIN_GC_LANGUAGE)) {
    case 0:
      language = @"English";
      break;
    case 1:
      language = @"German";
      break;
    case 2:
      language = @"French";
      break;
    case 3:
      language = @"Spanish";
      break;
    case 4:
      language = @"Italian";
      break;
    case 5:
      language = @"Dutch";
      break;
    default:
      language = @"Error";
      break;
  }
  
  self.languageLabel.text = DOLCoreLocalizedString(language);
}

- (void)mainMenuChanged {
  Config::SetBaseOrCurrent(Config::MAIN_SKIP_IPL, self.mainMenuSwitch.on);
}

@end
