// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "AnisotropicFilteringViewController.h"

#import "Common/EnumUtils.h"

#import "Core/Config/GraphicsSettings.h"

#import "VideoCommon/VideoConfig.h"

@interface AnisotropicFilteringViewController ()

@end

@implementation AnisotropicFilteringViewController {
  NSInteger _lastSelected;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  const AnisotropicFilteringMode anisotropicMode = Config::Get(Config::GFX_ENHANCE_MAX_ANISOTROPY);
  const TextureFilteringMode filteringMode = Config::Get(Config::GFX_ENHANCE_FORCE_TEXTURE_FILTERING);
  
  if (filteringMode == TextureFilteringMode::Default) {
    if (anisotropicMode == AnisotropicFilteringMode::Default) {
      _lastSelected = 0;
    } else {
      _lastSelected = 1 + Common::ToUnderlying(anisotropicMode);
    }
  } else if (filteringMode == TextureFilteringMode::Nearest) {
    _lastSelected = 6;
  } else if (filteringMode == TextureFilteringMode::Linear) {
    _lastSelected = 7 + Common::ToUnderlying(anisotropicMode);
  }
  
  UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_lastSelected inSection:0]];
  [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  if (_lastSelected != indexPath.row) {
    AnisotropicFilteringMode anisotropicMode;
    TextureFilteringMode filteringMode;
    
    switch (indexPath.row) {
      case 0: // Default
        anisotropicMode = AnisotropicFilteringMode::Default;
        filteringMode = TextureFilteringMode::Default;
        break;
      case 1: // Aniso 1x
        anisotropicMode = AnisotropicFilteringMode::Force1x;
        filteringMode = TextureFilteringMode::Default;
        break;
      case 2: // Aniso 2x
        anisotropicMode = AnisotropicFilteringMode::Force2x;
        filteringMode = TextureFilteringMode::Default;
        break;
      case 3: // Aniso 4x
        anisotropicMode = AnisotropicFilteringMode::Force4x;
        filteringMode = TextureFilteringMode::Default;
        break;
      case 4: // Aniso 8x
        anisotropicMode = AnisotropicFilteringMode::Force8x;
        filteringMode = TextureFilteringMode::Default;
        break;
      case 5: // Aniso 16x
        anisotropicMode = AnisotropicFilteringMode::Force16x;
        filteringMode = TextureFilteringMode::Default;
        break;
      case 6: // Force Nearest
        anisotropicMode = AnisotropicFilteringMode::Force1x;
        filteringMode = TextureFilteringMode::Nearest;
        break;
      case 7: // Linear
        anisotropicMode = AnisotropicFilteringMode::Force1x;
        filteringMode = TextureFilteringMode::Linear;
        break;
      case 8: // Force Linear + Aniso 2x
        anisotropicMode = AnisotropicFilteringMode::Force2x;
        filteringMode = TextureFilteringMode::Linear;
        break;
      case 9: // Force Linear + Aniso 4x
        anisotropicMode = AnisotropicFilteringMode::Force4x;
        filteringMode = TextureFilteringMode::Linear;
        break;
      case 10: // Force Linear + Aniso 8x
        anisotropicMode = AnisotropicFilteringMode::Force8x;
        filteringMode = TextureFilteringMode::Linear;
        break;
      case 11: // Force Linear + Aniso 16x
        anisotropicMode = AnisotropicFilteringMode::Force16x;
        filteringMode = TextureFilteringMode::Linear;
        break;
      default:
        anisotropicMode = AnisotropicFilteringMode::Default;
        filteringMode = TextureFilteringMode::Default;
        break;
    }
    
    Config::SetBase(Config::GFX_ENHANCE_MAX_ANISOTROPY, anisotropicMode);
    Config::SetBase(Config::GFX_ENHANCE_FORCE_TEXTURE_FILTERING, filteringMode);
    
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    UITableViewCell* oldCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_lastSelected inSection:0]];
    oldCell.accessoryType = UITableViewCellAccessoryNone;
    
    _lastSelected = indexPath.row;
  }
  
  [tableView deselectRowAtIndexPath:indexPath animated:true];
}

@end
