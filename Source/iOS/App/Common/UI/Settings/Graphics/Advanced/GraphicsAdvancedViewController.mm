// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "GraphicsAdvancedViewController.h"

#import "Core/Config/GraphicsSettings.h"
#import "Core/Config/SYSCONFSettings.h"

#import "LocalizationUtil.h"

#import "VideoCommon/VideoConfig.h"

@interface GraphicsAdvancedViewController ()

@end

@implementation GraphicsAdvancedViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self.fpsCell registerSetting:Config::GFX_SHOW_FPS];
  [self.vpsCell registerSetting:Config::GFX_SHOW_VPS];
  [self.speedCell registerSetting:Config::GFX_SHOW_SPEED];
  [self.frameTimesCell registerSetting:Config::GFX_SHOW_FTIMES];
  [self.vblankTimesCell registerSetting:Config::GFX_SHOW_VTIMES];
  [self.graphsCell registerSetting:Config::GFX_SHOW_GRAPHS];
  [self.renderTimeCell registerSetting:Config::GFX_LOG_RENDER_TIME_TO_FILE];
  [self.colorsCell registerSetting:Config::GFX_SHOW_SPEED_COLORS];
  [self.statisticsCell registerSetting:Config::GFX_OVERLAY_STATS];
  [self.apiValidationCell registerSetting:Config::GFX_ENABLE_VALIDATION_LAYER];
  [self.loadTexturesCell registerSetting:Config::GFX_HIRES_TEXTURES];
  [self.prefetchTexturesCell registerSetting:Config::GFX_CACHE_HIRES_TEXTURES];
  [self.disableEfbVramCell registerSetting:Config::GFX_HACK_DISABLE_COPY_TO_VRAM];
  [self.cropCell registerSetting:Config::GFX_CROP];
  [self.backendMultithreadingCell registerSetting:Config::GFX_BACKEND_MULTITHREADING];
  [self.vsPointLineExpansionCell registerSetting:Config::GFX_PREFER_VS_FOR_LINE_POINT_EXPANSION];
  [self.cpuCullCell registerSetting:Config::GFX_CPU_CULL];
  [self.deferEfbCacheCell registerSetting:Config::GFX_HACK_EFB_DEFER_INVALIDATION];
  [self.manualSamplingCell registerSetting:Config::GFX_HACK_FAST_TEXTURE_SAMPLING shouldReverse:true];
  
  [self.loadTexturesCell.boolSwitch addValueChangedTarget:self action:@selector(updatePrefetchTexturesEnabled)];
  
  bool enableVsExpansionSwitch = g_Config.backend_info.bSupportsGeometryShaders && g_Config.backend_info.bSupportsVSLinePointExpand;
  [self.vsPointLineExpansionCell.boolSwitch setEnabled:enableVsExpansionSwitch];
  
  [self updatePrefetchTexturesEnabled];
  
  self.graphicsModsSwitch.on = Config::Get(Config::GFX_MODS_ENABLE);
  [self.graphicsModsSwitch addValueChangedTarget:self action:@selector(graphicsModsChanged)];
  
  self.progressiveScanSwitch.on = Config::Get(Config::SYSCONF_PROGRESSIVE_SCAN);
  [self.progressiveScanSwitch addValueChangedTarget:self action:@selector(progressiveScanChanged)];
}

- (void)updatePrefetchTexturesEnabled {
  self.prefetchTexturesCell.boolSwitch.enabled = self.loadTexturesCell.boolSwitch.on;
}

- (void)graphicsModsChanged {
  Config::SetBaseOrCurrent(Config::GFX_MODS_ENABLE, self.graphicsModsSwitch.on);
}

- (void)progressiveScanChanged {
  Config::SetBase(Config::SYSCONF_PROGRESSIVE_SCAN, self.progressiveScanSwitch.on);
}

- (void)tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath {
  NSString* message = nil;
  
  switch (indexPath.section) {
    case 0:
      switch (indexPath.row) {
        case 0:
          message = @"Shows the number of distinct frames rendered per second as a measure of "
                    "visual smoothness.<br><br><dolphin_emphasis>If unsure, leave this "
                    "unchecked.</dolphin_emphasis>";
          break;
        case 1:
          message = @"Shows the number of frames rendered per second as a measure of "
                    "emulation speed.<br><br><dolphin_emphasis>If unsure, leave this "
                    "unchecked.</dolphin_emphasis>";
          break;
        case 2:
          message = @"Shows the % speed of emulation compared to full speed."
                    "<br><br><dolphin_emphasis>If unsure, leave this "
                    "unchecked.</dolphin_emphasis>";
          break;
        case 3:
          message = @"Shows the average time in ms between each distinct rendered frame alongside "
                    "the standard deviation.<br><br><dolphin_emphasis>If unsure, leave this "
                    "unchecked.</dolphin_emphasis>";
          break;
        case 4:
          message = @"Shows the average time in ms between each rendered frame alongside "
                    "the standard deviation.<br><br><dolphin_emphasis>If unsure, leave this "
                    "unchecked.</dolphin_emphasis>";
          break;
        case 5:
          message = @"Shows frametime graph along with statistics as a representation of "
                    "emulation performance.<br><br><dolphin_emphasis>If unsure, leave this "
                    "unchecked.</dolphin_emphasis>";
          break;
        case 6:
          message = @"Logs the render time of every frame to User/Logs/render_time.txt.<br><br>Use this "
                    "feature to measure Dolphin's performance.<br><br><dolphin_emphasis>If "
                    "unsure, leave this unchecked.</dolphin_emphasis>";
          break;
        case 7:
          message = @"Changes the color of the FPS counter depending on emulation speed."
                    "<br><br><dolphin_emphasis>If unsure, leave this "
                    "checked.</dolphin_emphasis>";
          break;
      }
      break;
    case 1:
      switch (indexPath.row) {
        case 0:
          message = @"Shows various rendering statistics.<br><br><dolphin_emphasis>If unsure, "
                    "leave this unchecked.</dolphin_emphasis>";
          break;
        case 1:
          message = @"Enables validation of API calls made by the video backend, which may assist in "
                    "debugging graphical issues. On the Vulkan and D3D backends, this also enables "
                    "debug symbols for the compiled shaders.<br><br><dolphin_emphasis>If unsure, "
                    "leave this unchecked.</dolphin_emphasis>";
          break;
      }
      break;
    case 2:
      switch (indexPath.row) {
        case 0:
          message = @"Loads custom textures from User/Load/Textures/&lt;game_id&gt;/ and "
                    "User/Load/DynamicInputTextures/&lt;game_id&gt;/.<br><br><dolphin_emphasis>If "
                    "unsure, leave this unchecked.</dolphin_emphasis>";
          break;
        case 1:
          message = @"Caches custom textures to system RAM on startup.<br><br>This can require exponentially "
                    "more RAM but fixes possible stuttering.<br><br><dolphin_emphasis>If unsure, leave this "
                    "unchecked.</dolphin_emphasis>";
          break;
        case 2:
          message = @"Disables the VRAM copy of the EFB, forcing a round-trip to RAM. Inhibits all "
                    "upscaling.<br><br><dolphin_emphasis>If unsure, leave this "
                    "unchecked.</dolphin_emphasis>";
          break;
        case 3:
          message = @"Loads graphics mods from User/Load/GraphicsMods/.<br><br><dolphin_emphasis>If "
                    "unsure, leave this unchecked.</dolphin_emphasis>";
          break;
      }
      break;
    case 3:
      switch (indexPath.row) {
        case 0:
          message = @"Crops the picture from its native aspect ratio to 4:3 or "
                    "16:9.<br><br><dolphin_emphasis>If unsure, leave this unchecked.</dolphin_emphasis>";
          break;
        case 1:
          message = @"Enables progressive scan if supported by the emulated software. Most games don't have "
                    "any issue with this.<br><br><dolphin_emphasis>If unsure, leave this "
                    "unchecked.</dolphin_emphasis>";
          break;
        case 2:
          message = @"Enables multithreaded command submission in backends where supported. Enabling "
                    "this option may result in a performance improvement on systems with more than "
                    "two CPU cores. Currently, this is limited to the Vulkan backend.<br><br>"
                    "<dolphin_emphasis>If unsure, leave this checked.</dolphin_emphasis>";
          break;
        case 3: {
          NSString* messageFormat = @"On backends that support both using the geometry shader and the vertex shader "
                                    "for expanding points and lines, selects the vertex shader for the job.  May "
                                    "affect performance."
                                    "<br><br>%1";
          
          NSString* extraFormat;
          
          if (!g_Config.backend_info.bSupportsGeometryShaders) {
            extraFormat = @"Forced on because %1 doesn't support geometry shaders.";
          } else if (!g_Config.backend_info.bSupportsVSLinePointExpand) {
            extraFormat = @"Forced off because %1 doesn't support VS expansion.";
          } else {
            extraFormat = @"<dolphin_emphasis>If unsure, leave this unchecked.</dolphin_emphasis>";
          }
          
          NSString* extraMessage = [NSString stringWithFormat:DOLCoreLocalizedStringWithArgs(extraFormat, @"s"), g_Config.backend_info.DisplayName.c_str()];
          
          NSString* message = [NSString stringWithFormat:DOLCoreLocalizedStringWithArgs(messageFormat, @"@"), extraMessage];
          
          [self showHelpWithMessage:message];
          
          return;
        }
        case 4:
          message = @"Cull vertices on the CPU to reduce the number of draw calls required.  "
                    "May affect performance and draw statistics.<br><br>"
                    "<dolphin_emphasis>If unsure, leave this unchecked.</dolphin_emphasis>";
          break;
      }
      break;
    case 4:
      switch (indexPath.row) {
        case 0:
          message = @"Defers invalidation of the EFB access cache until a GPU synchronization command "
                    "is executed. If disabled, the cache will be invalidated with every draw call. "
                    "<br><br>May improve performance in some games which rely on CPU EFB Access at the cost "
                    "of stability.<br><br><dolphin_emphasis>If unsure, leave this "
                    "unchecked.</dolphin_emphasis>";
          break;
        case 1:
          message = @"Use a manual implementation of texture sampling instead of the graphics backend's built-in "
                    "functionality.<br><br>"
                    "This setting can fix graphical issues in some games on certain GPUs, most commonly vertical "
                    "lines on FMVs. In addition to this, enabling Manual Texture Sampling will allow for correct "
                    "emulation of texture wrapping special cases (at 1x IR or when scaled EFB is disabled, and "
                    "with custom textures disabled) and better emulates Level of Detail calculation.<br><br>"
                    "This comes at the cost of potentially worse performance, especially at higher internal "
                    "resolutions; additionally, Anisotropic Filtering is currently incompatible with Manual "
                    "Texture Sampling.<br><br>"
                    "<dolphin_emphasis>If unsure, leave this unchecked.</dolphin_emphasis>";
          break;
      }
      break;
  }
  
  [self showHelpWithLocalizable:message];
}

@end
