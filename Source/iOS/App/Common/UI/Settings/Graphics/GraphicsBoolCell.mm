// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "GraphicsBoolCell.h"

#import "Common/Config/Config.h"

@implementation GraphicsBoolCell {
  const Config::Info<bool>* _setting;
  bool _shouldReverse;
}

- (void)registerSetting:(const Config::Info<bool>&) setting {
  [self registerSetting:setting shouldReverse:false];
}

- (void)registerSetting:(const Config::Info<bool>&) setting shouldReverse:(bool)reverse {
  _setting = &setting;
  _shouldReverse = reverse;
  
  UIFont* font;
  if (Config::GetActiveLayerForConfig(setting) != Config::LayerType::Base) {
    font = [UIFont boldSystemFontOfSize:self.boolLabel.font.pointSize];
  } else {
    font = [UIFont systemFontOfSize:self.boolLabel.font.pointSize];
  }
  
  self.boolLabel.font = font;
  
  self.boolSwitch.on = Config::Get(setting) ^ reverse;
  [self.boolSwitch addValueChangedTarget:self action:@selector(switchChanged)];
}

- (void)switchChanged {
  Config::SetBaseOrCurrent(*_setting, self.boolSwitch.on ^ _shouldReverse);
}

@end
