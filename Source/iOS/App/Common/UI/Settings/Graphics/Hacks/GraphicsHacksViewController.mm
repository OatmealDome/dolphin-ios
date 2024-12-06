// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "GraphicsHacksViewController.h"

#import "Core/Config/GraphicsSettings.h"

@interface GraphicsHacksViewController ()

@end

@implementation GraphicsHacksViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self.skipEfbCell registerSetting:Config::GFX_HACK_EFB_ACCESS_ENABLE shouldReverse:true];
  [self.efbToTextureCell registerSetting:Config::GFX_HACK_SKIP_EFB_COPY_TO_RAM];
  [self.formatChangesCell registerSetting:Config::GFX_HACK_EFB_EMULATE_FORMAT_CHANGES shouldReverse:true];
  [self.deferEfbCell registerSetting:Config::GFX_HACK_DEFER_EFB_COPIES];
  [self.gpuTextureCell registerSetting:Config::GFX_ENABLE_GPU_TEXTURE_DECODING];
  [self.xfbToTextureCell registerSetting:Config::GFX_HACK_SKIP_XFB_COPY_TO_RAM];
  [self.presentXfbCell registerSetting:Config::GFX_HACK_IMMEDIATE_XFB];
  [self.duplicateFramesCell registerSetting:Config::GFX_HACK_SKIP_DUPLICATE_XFBS];
  [self.fastDepthCell registerSetting:Config::GFX_FAST_DEPTH_CALC];
  [self.vertexRoundingCell registerSetting:Config::GFX_HACK_VERTEX_ROUNDING];
  [self.boundingBoxCell registerSetting:Config::GFX_HACK_BBOX_ENABLE shouldReverse:true];
  [self.textureCacheCell registerSetting:Config::GFX_SAVE_TEXTURE_CACHE_TO_STATE];
  [self.viSkipCell registerSetting:Config::GFX_HACK_VI_SKIP];
  
  [self.efbToTextureCell.boolSwitch addValueChangedTarget:self action:@selector(updateDeferEnabled)];
  [self.xfbToTextureCell.boolSwitch addValueChangedTarget:self action:@selector(updateDeferEnabled)];
  
  [self updateDeferEnabled];
  
  [self.presentXfbCell.boolSwitch addValueChangedTarget:self action:@selector(updateDuplicateFramesEnabled)];
  [self.viSkipCell.boolSwitch addValueChangedTarget:self action:@selector(updateDuplicateFramesEnabled)];
  
  [self updateDuplicateFramesEnabled];
  
  auto samples = Config::Get(Config::GFX_SAFE_TEXTURE_CACHE_COLOR_SAMPLES);
  
  int sliderPosition;
  switch (samples) {
    case 512:
      sliderPosition = 1;
      break;
    case 128:
      sliderPosition = 2;
      break;
    case 0:
      sliderPosition = 0;
      break;
    default:
      sliderPosition = -1;
      break;
  }
  
  if (sliderPosition >= 0) {
    self.textureAccuracySlider.value = sliderPosition;
  } else {
    // Custom value
    self.textureAccuracySlider.enabled = false;
  }
}

- (void)updateDeferEnabled {
  const bool can_defer = self.efbToTextureCell.boolSwitch.on && self.xfbToTextureCell.boolSwitch.on;
  self.deferEfbCell.boolSwitch.enabled = !can_defer;
}

- (void)updateDuplicateFramesEnabled {
  const bool disabled = self.presentXfbCell.boolSwitch.on || self.viSkipCell.boolSwitch.on;
  
  self.duplicateFramesCell.boolSwitch.enabled = !disabled;
}

- (IBAction)accuracyUpdated:(id)sender {
  if (!self.textureAccuracySlider.enabled) {
    return;
  }
  
  int sliderPosition = (int)self.textureAccuracySlider.value;
  
  int samples = 0;
  switch (sliderPosition) {
    case 0:
      samples = 0;
      break;
    case 1:
      samples = 512;
      break;
    case 2:
    default:
      samples = 128;
      break;
  }

  Config::SetBaseOrCurrent(Config::GFX_SAFE_TEXTURE_CACHE_COLOR_SAMPLES, samples);
  self.textureAccuracySlider.value = sliderPosition;
}

- (IBAction)accuracyHelpPressed:(id)sender {
  [self showHelpWithLocalizable:@"Adjusts the accuracy at which the GPU receives texture updates from RAM.<br><br>"
                                "The \"Safe\" setting eliminates the likelihood of the GPU missing texture updates "
                                "from RAM. Lower accuracies cause in-game text to appear garbled in certain "
                                "games.<br><br><dolphin_emphasis>If unsure, select the rightmost "
                                "value.</dolphin_emphasis>"];
}

- (void)tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath {
  NSString* message = nil;
  
  switch (indexPath.section) {
    case 0:
      switch (indexPath.row) {
        case 0:
          message = @"Ignores any requests from the CPU to read from or write to the EFB. "
                    "<br><br>Improves performance in some games, but will disable all EFB-based "
                    "graphical effects or gameplay-related features.<br><br><dolphin_emphasis>If unsure, "
                    "leave this checked.</dolphin_emphasis>";
          break;
        case 1:
          message = @"Stores EFB copies exclusively on the GPU, bypassing system memory. Causes graphical defects "
                    "in a small number of games.<br><br>Enabled = EFB Copies to Texture<br>Disabled = EFB "
                    "Copies to "
                    "RAM (and Texture)<br><br><dolphin_emphasis>If unsure, leave this "
                    "checked.</dolphin_emphasis>";
          break;
        case 2:
          message = @"Ignores any changes to the EFB format.<br><br>Improves performance in many games "
                    "without "
                    "any negative effect. Causes graphical defects in a small number of other "
                    "games.<br><br><dolphin_emphasis>If unsure, leave this checked.</dolphin_emphasis>";
          break;
        case 3:
          message = @"Waits until the game synchronizes with the emulated GPU before writing the contents of EFB "
                    "copies to RAM.<br><br>Reduces the overhead of EFB RAM copies, providing a performance "
                    "boost in "
                    "many games, at the risk of breaking those which do not safely synchronize with the "
                    "emulated GPU.<br><br><dolphin_emphasis>If unsure, leave this "
                    "checked.</dolphin_emphasis>";
      }
      break;
    case 1:
      switch (indexPath.row) {
        case 0:
          return; // handled elsewhere
        case 1:
          message = @"Enables texture decoding using the GPU instead of the CPU.<br><br>This may result in "
                    "performance gains in some scenarios, or on systems where the CPU is the "
                    "bottleneck.<br><br><dolphin_emphasis>If unsure, leave this "
                    "unchecked.</dolphin_emphasis>";
          break;
      }
      break;
    case 2:
      switch (indexPath.row) {
        case 0:
          message = @"Stores XFB copies exclusively on the GPU, bypassing system memory. Causes graphical defects "
                    "in a small number of games.<br><br>Enabled = XFB Copies to "
                    "Texture<br>Disabled = XFB Copies to RAM (and Texture)<br><br><dolphin_emphasis>If "
                    "unsure, leave this checked.</dolphin_emphasis>";
          break;
        case 1:
          message = @"Displays XFB copies as soon as they are created, instead of waiting for "
                    "scanout.<br><br>Can cause graphical defects in some games if the game doesn't "
                    "expect all XFB copies to be displayed. However, turning this setting on reduces "
                    "latency.<br><br><dolphin_emphasis>If unsure, leave this unchecked.</dolphin_emphasis>";
          break;
        case 2:
          message = @"Skips presentation of duplicate frames (XFB copies) in 25fps/30fps games. This may improve "
                    "performance on low-end devices, while making frame pacing less consistent.<br><br "
                    "/>Disable this "
                    "option as well as enabling V-Sync for optimal frame pacing.<br><br><dolphin_emphasis>If "
                    "unsure, leave this "
                    "checked.</dolphin_emphasis>";
          break;
      }
      break;
    case 3:
      switch (indexPath.row) {
        case 0:
          message = @"Uses a less accurate algorithm to calculate depth values.<br><br>Causes issues in a few "
                    "games, but can result in a decent speed increase depending on the game and/or "
                    "GPU.<br><br><dolphin_emphasis>If unsure, leave this checked.</dolphin_emphasis>";
          break;
        case 1:
          message = @"Rounds 2D vertices to whole pixels and rounds the viewport size to a whole number.<br><br>"
                    "Fixes graphical problems in some games at higher internal resolutions. This setting has no "
                    "effect when native internal resolution is used.<br><br>"
                    "<dolphin_emphasis>If unsure, leave this unchecked.</dolphin_emphasis>";
          break;
        case 2:
          message = @"Disables bounding box emulation.<br><br>This may improve GPU performance "
                    "significantly, but some games will break.<br><br><dolphin_emphasis>If "
                    "unsure, leave this checked.</dolphin_emphasis>";
          break;
        case 3:
          message = @"Includes the contents of the embedded frame buffer (EFB) and upscaled EFB copies "
                    "in save states. Fixes missing and/or non-upscaled textures/objects when loading "
                    "states at the cost of additional save/load time.<br><br><dolphin_emphasis>If "
                    "unsure, leave this checked.</dolphin_emphasis>";
          break;
        case 4:
          message = @"Skips VI interrupts when lag is detected, allowing for "
                    "smooth audio playback when emulation speed is not 100%. <br><br>"
                    "<dolphin_emphasis>WARNING: Can cause freezes and compatibility "
                    "issues.</dolphin_emphasis> <br><br>"
                    "<dolphin_emphasis>If unsure, leave this unchecked.</dolphin_emphasis>";
          break;
      }
      break;
  }
  
  [self showHelpWithLocalizable:message];
}

@end
