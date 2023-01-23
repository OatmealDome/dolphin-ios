// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "AnisotropicFilteringViewController.h"

#import "Core/Config/GraphicsSettings.h"

#import "VideoCommon/VideoConfig.h"

@interface AnisotropicFilteringViewController ()

@end

@implementation AnisotropicFilteringViewController {
  NSInteger _lastSelected;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  const int maxAnisotropy = Config::Get(Config::GFX_ENHANCE_MAX_ANISOTROPY);
  const TextureFilteringMode filteringMode = Config::Get(Config::GFX_ENHANCE_FORCE_TEXTURE_FILTERING);
  
  if (filteringMode == TextureFilteringMode::Default) {
    _lastSelected = maxAnisotropy;
  } else if (filteringMode == TextureFilteringMode::Nearest) {
    _lastSelected = 5;
  } else if (filteringMode == TextureFilteringMode::Linear) {
    _lastSelected = 6 + maxAnisotropy;
  }
  
  UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_lastSelected inSection:0]];
  [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  if (_lastSelected != indexPath.row) {
    int maxAnisotropy;
    TextureFilteringMode filteringMode;
    
    switch (indexPath.row) {
      case 0: // Default
        maxAnisotropy = 0;
        filteringMode = TextureFilteringMode::Default;
        break;
      case 1: // Aniso 2x
        maxAnisotropy = 1;
        filteringMode = TextureFilteringMode::Default;
        break;
      case 2: // Aniso 4x
        maxAnisotropy = 2;
        filteringMode = TextureFilteringMode::Default;
        break;
      case 3: // Aniso 8x
        maxAnisotropy = 3;
        filteringMode = TextureFilteringMode::Default;
        break;
      case 4: // Aniso 16x
        maxAnisotropy = 4;
        filteringMode = TextureFilteringMode::Default;
        break;
      case 5: // Force Nearest
        maxAnisotropy = 0;
        filteringMode = TextureFilteringMode::Nearest;
        break;
      case 6: // Linear
        maxAnisotropy = 0;
        filteringMode = TextureFilteringMode::Linear;
        break;
      case 7: // Force Linear + Aniso 2x
        maxAnisotropy = 1;
        filteringMode = TextureFilteringMode::Linear;
        break;
      case 8: // Force Linear + Aniso 4x
        maxAnisotropy = 2;
        filteringMode = TextureFilteringMode::Linear;
        break;
      case 9: // Force Linear + Aniso 8x
        maxAnisotropy = 3;
        filteringMode = TextureFilteringMode::Linear;
        break;
      case 10: // Force Linear + Aniso 16x
        maxAnisotropy = 4;
        filteringMode = TextureFilteringMode::Linear;
        break;
      default:
        maxAnisotropy = 0;
        filteringMode = TextureFilteringMode::Default;
        break;
    }
    
    Config::SetBase(Config::GFX_ENHANCE_MAX_ANISOTROPY, maxAnisotropy);
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
