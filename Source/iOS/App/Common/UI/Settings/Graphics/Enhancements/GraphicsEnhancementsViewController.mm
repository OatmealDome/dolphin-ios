// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "GraphicsEnhancementsViewController.h"

#import "Core/Config/GraphicsSettings.h"

#import "VideoCommon/VideoConfig.h"

#import "LocalizationUtil.h"

@interface GraphicsEnhancementsViewController ()

@end

@implementation GraphicsEnhancementsViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self.resolutionCell registerSetting:Config::GFX_EFB_SCALE];
  [self.filteringCell registerSetting:Config::GFX_ENHANCE_MAX_ANISOTROPY];
  [self.scaledEfbCell registerSetting:Config::GFX_HACK_COPY_EFB_SCALED];
  [self.fogCell registerSetting:Config::GFX_DISABLE_FOG];
  [self.filterCell registerSetting:Config::GFX_ENHANCE_DISABLE_COPY_FILTER];
  [self.lightingCell registerSetting:Config::GFX_ENABLE_PIXEL_LIGHTING];
  [self.widescreenHackCell registerSetting:Config::GFX_WIDESCREEN_HACK];
  [self.colorCell registerSetting:Config::GFX_ENHANCE_FORCE_TRUE_COLOR];
  [self.mipmapCell registerSetting:Config::GFX_ENHANCE_ARBITRARY_MIPMAP_DETECTION];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  const int efb_scale = Config::Get(Config::GFX_EFB_SCALE);
  if (efb_scale > 0) {
    NSString* resolution = [NSString stringWithFormat:@"%dx", efb_scale];
    self.resolutionCell.choiceSettingLabel.text = resolution;
  } else {
    self.resolutionCell.choiceSettingLabel.text = DOLCoreLocalizedString(@"Auto");
  }
  
  const AnisotropicFilteringMode anisotropicMode = Config::Get(Config::GFX_ENHANCE_MAX_ANISOTROPY);
  const TextureFilteringMode filteringMode = Config::Get(Config::GFX_ENHANCE_FORCE_TEXTURE_FILTERING);
  
  NSString* filteringAnisotropy;
  
  switch (anisotropicMode) {
    case AnisotropicFilteringMode::Default:
      filteringAnisotropy = @"Default";
      break;
    case AnisotropicFilteringMode::Force1x:
      filteringAnisotropy = @"1x Anisotropic";
      break;
    case AnisotropicFilteringMode::Force2x:
      filteringAnisotropy = @"2x Anisotropic";
      break;
    case AnisotropicFilteringMode::Force4x:
      filteringAnisotropy = @"4x Anisotropic";
      break;
    case AnisotropicFilteringMode::Force8x:
      filteringAnisotropy = @"8x Anisotropic";
      break;
    case AnisotropicFilteringMode::Force16x:
      filteringAnisotropy = @"16x Anisotropic";
      break;
    default:
      filteringAnisotropy = @"Error";
      break;
  }
  
  NSString* filtering;
  
  if (filteringMode == TextureFilteringMode::Default) {
    filtering = filteringAnisotropy;
  } else if (filteringMode == TextureFilteringMode::Nearest) {
    filtering = @"Force Nearest and 1x Anisotropic";
  } else if (filteringMode == TextureFilteringMode::Linear) {
    filtering = [NSString stringWithFormat:@"Force Linear and %@", filteringAnisotropy];
  }
  
  self.filteringCell.choiceSettingLabel.text = DOLCoreLocalizedString(filtering);
}

- (void)tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath {
  NSString* message = nil;
  
  switch (indexPath.section) {
    case 0:
      switch (indexPath.row) {
        case 0:
          message = @"Controls the rendering resolution.<br><br>A high resolution greatly improves "
                    "visual quality, but also greatly increases GPU load and can cause issues in "
                    "certain games. Generally speaking, the lower the internal resolution, the "
                    "better performance will be.<br><br><dolphin_emphasis>If unsure, "
                    "select Native.</dolphin_emphasis>";
          break;
        case 1:
          message = @"Adjust the texture filtering. Anisotropic filtering enhances the visual quality of textures "
                    "that are at oblique viewing angles. Force Nearest and Force Linear override the texture "
                    "scaling filter selected by the game.<br><br>Any option except 'Default' will alter the look "
                    "of the game's textures and might cause issues in a small number of "
                    "games.<br><br><dolphin_emphasis>If unsure, select 'Default'.</dolphin_emphasis>";
          break;
        case 2:
          message = @"Greatly increases the quality of textures generated using render-to-texture "
                    "effects.<br><br>Slightly increases GPU load and causes relatively few graphical "
                    "issues. Raising the internal resolution will improve the effect of this setting. "
                    "<br><br><dolphin_emphasis>If unsure, leave this checked.</dolphin_emphasis>";
          break;
        case 3:
          message = @"Makes distant objects more visible by removing fog, thus increasing the overall "
                    "detail.<br><br>Disabling fog will break some games which rely on proper fog "
                    "emulation.<br><br><dolphin_emphasis>If unsure, leave this "
                    "unchecked.</dolphin_emphasis>";
          break;
        case 4:
          message = @"Disables the blending of adjacent rows when copying the EFB. This is known in "
                    "some games as \"deflickering\" or \"smoothing\".<br><br>Disabling the filter has no "
                    "effect on performance, but may result in a sharper image. Causes few "
                    "graphical issues.<br><br><dolphin_emphasis>If unsure, leave this "
                    "checked.</dolphin_emphasis>";
          break;
        case 5:
          message = @"Calculates lighting of 3D objects per-pixel rather than per-vertex, smoothing out the "
                    "appearance of lit polygons and making individual triangles less noticeable.<br><br "
                    "/>Rarely "
                    "causes slowdowns or graphical issues.<br><br><dolphin_emphasis>If unsure, leave "
                    "this unchecked.</dolphin_emphasis>";
          break;
        case 6:
          message = @"Forces the game to output graphics for any aspect ratio. Use with \"Aspect Ratio\" set to "
                    "\"Force 16:9\" to force 4:3-only games to run at 16:9.<br><br>Rarely produces good "
                    "results and "
                    "often partially breaks graphics and game UIs. Unnecessary (and detrimental) if using any "
                    "AR/Gecko-code widescreen patches.<br><br><dolphin_emphasis>If unsure, leave "
                    "this unchecked.</dolphin_emphasis>";
          break;
        case 7:
          message = @"Forces the game to render the RGB color channels in 24-bit, thereby increasing "
                    "quality by reducing color banding.<br><br>Has no impact on performance and causes "
                    "few graphical issues.<br><br><dolphin_emphasis>If unsure, leave this "
                    "checked.</dolphin_emphasis>";
          break;
        case 8:
          message = @"Enables detection of arbitrary mipmaps, which some games use for special distance-based "
                    "effects.<br><br>May have false positives that result in blurry textures at increased "
                    "internal "
                    "resolution, such as in games that use very low resolution mipmaps. Disabling this can also "
                    "reduce stutter in games that frequently load new textures. This feature is not compatible "
                    "with GPU Texture Decoding.<br><br><dolphin_emphasis>If unsure, leave this "
                    "checked.</dolphin_emphasis>";
          break;
      }
      break;
  }
  
  [self showHelpWithLocalizable:message];
}

@end
