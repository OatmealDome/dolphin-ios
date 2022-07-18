// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "GraphicsEnhancementsViewController.h"

#import "Core/Config/GraphicsSettings.h"

#import "LocalizationUtil.h"

@interface GraphicsEnhancementsViewController ()

@end

@implementation GraphicsEnhancementsViewController

- (void)viewDidLoad {
  [self.resolutionCell registerSetting:Config::GFX_EFB_SCALE];
  [self.filteringCell registerSetting:Config::GFX_ENHANCE_MAX_ANISOTROPY];
  [self.scaledEfbCell registerSetting:Config::GFX_HACK_COPY_EFB_SCALED];
  [self.textureFilteringCell registerSetting:Config::GFX_ENHANCE_FORCE_FILTERING];
  [self.fogCell registerSetting:Config::GFX_DISABLE_FOG];
  [self.filterCell registerSetting:Config::GFX_ENHANCE_DISABLE_COPY_FILTER];
  [self.lightingCell registerSetting:Config::GFX_ENABLE_PIXEL_LIGHTING];
  [self.widescreenHackCell registerSetting:Config::GFX_WIDESCREEN_HACK];
  [self.colorCell registerSetting:Config::GFX_ENHANCE_FORCE_TRUE_COLOR];
  [self.mipmapCell registerSetting:Config::GFX_ENHANCE_ARBITRARY_MIPMAP_DETECTION];
}

- (void)viewWillAppear:(BOOL)animated {
  NSString* resolution = [NSString stringWithFormat:@"%dx", Config::Get(Config::GFX_EFB_SCALE)];
  self.resolutionCell.choiceSettingLabel.text = resolution;
  
  NSString* filtering;
  switch (Config::Get(Config::GFX_ENHANCE_MAX_ANISOTROPY)) {
    case 0:
      filtering = @"1x";
      break;
    case 1:
      filtering = @"2x";
      break;
    case 2:
      filtering = @"4x";
      break;
    case 3:
      filtering = @"8x";
      break;;
    case 4:
      filtering = @"16x";
      break;
    default:
      filtering = @"Error";
      break;
  }
  
  self.filteringCell.choiceSettingLabel.text = DOLCoreLocalizedString(filtering);
}

@end
