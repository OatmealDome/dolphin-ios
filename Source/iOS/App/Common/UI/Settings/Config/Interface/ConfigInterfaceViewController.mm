// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "ConfigInterfaceViewController.h"

#import "Core/Config/MainSettings.h"
#import "Core/Config/UISettings.h"

@interface ConfigInterfaceViewController ()

@end

@implementation ConfigInterfaceViewController

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  self.namesSwitch.on = Config::Get(Config::MAIN_USE_BUILT_IN_TITLE_DATABASE);
  [self.namesSwitch addValueChangedTarget:self action:@selector(namesChanged)];
  
  self.coversSwitch.on = Config::Get(Config::MAIN_USE_GAME_COVERS);
  [self.coversSwitch addValueChangedTarget:self action:@selector(coversChanged)];
  
  self.stopSwitch.on = Config::Get(Config::MAIN_CONFIRM_ON_STOP);
  [self.stopSwitch addValueChangedTarget:self action:@selector(stopChanged)];
  
  self.panicHandlersSwitch.on = Config::Get(Config::MAIN_USE_PANIC_HANDLERS);
  [self.panicHandlersSwitch addValueChangedTarget:self action:@selector(panicHandlersChanged)];
  
  self.osdMessagesSwitch.on = Config::Get(Config::MAIN_OSD_MESSAGES);
  [self.osdMessagesSwitch addValueChangedTarget:self action:@selector(osdMessagesChanged)];
}

- (void)namesChanged {
  Config::SetBase(Config::MAIN_USE_BUILT_IN_TITLE_DATABASE, self.namesSwitch.on);
}

- (void)coversChanged {
  Config::SetBase(Config::MAIN_USE_GAME_COVERS, self.coversSwitch.on);
}

- (void)stopChanged {
  Config::SetBase(Config::MAIN_CONFIRM_ON_STOP, self.stopSwitch.on);
}

- (void)panicHandlersChanged {
  Config::SetBase(Config::MAIN_USE_PANIC_HANDLERS, self.panicHandlersSwitch.on);
}

- (void)osdMessagesChanged {
  Config::SetBase(Config::MAIN_OSD_MESSAGES, self.osdMessagesSwitch.on);
}

@end
