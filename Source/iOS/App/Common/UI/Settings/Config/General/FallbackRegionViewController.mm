// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "FallbackRegionViewController.h"

#import "Core/Config/MainSettings.h"

#import "FallbackRegionCell.h"
#import "LocalizationUtil.h"

@interface FallbackRegionViewController ()

@end

@implementation FallbackRegionViewController {
  NSInteger _lastSelected;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  switch (Config::Get(Config::MAIN_FALLBACK_REGION)) {
    case DiscIO::Region::NTSC_J:
      _lastSelected = 0;
      break;
    case DiscIO::Region::NTSC_U:
      _lastSelected = 1;
      break;
    case DiscIO::Region::PAL:
      _lastSelected = 2;
      break;
    case DiscIO::Region::NTSC_K:
      _lastSelected = 3;
      break;
    default:
      _lastSelected = 0;
      break;
  }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
  return 4;
}

- (UITableViewCell *)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  FallbackRegionCell* cell = [tableView dequeueReusableCellWithIdentifier:@"RegionCell"];
  
  NSString* region;
  switch (indexPath.row) {
    case 0:
      region = @"NTSC-J";
      break;
    case 1:
      region = @"NTSC-U";
      break;
    case 2:
      region = @"PAL";
      break;
    case 3:
      region = @"NTSC-K";
      break;
    default:
      region = @"Error";
      break;
  }
  
  cell.regionLabel.text = DOLCoreLocalizedString(region);
  
  if (_lastSelected == indexPath.row) {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  } else {
    cell.accessoryType = UITableViewCellAccessoryNone;
  }
  
  return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  if (_lastSelected != indexPath.row) {
    DiscIO::Region region;
    
    switch (indexPath.row) {
      case 0:
        region = DiscIO::Region::NTSC_J;
        break;
      case 1:
        region = DiscIO::Region::NTSC_U;
        break;
      case 2:
        region = DiscIO::Region::PAL;
        break;
      case 3:
        region = DiscIO::Region::NTSC_K;
        break;
      default:
        region = DiscIO::Region::NTSC_J;
        break;
    }
    
    Config::SetBase(Config::MAIN_FALLBACK_REGION, region);
    
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    UITableViewCell* oldCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_lastSelected inSection:0]];
    oldCell.accessoryType = UITableViewCellAccessoryNone;
    
    _lastSelected = indexPath.row;
  }
  
  [tableView deselectRowAtIndexPath:indexPath animated:true];
}

@end
