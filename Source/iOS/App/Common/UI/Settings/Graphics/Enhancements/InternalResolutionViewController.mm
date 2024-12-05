// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "InternalResolutionViewController.h"

#import "Core/Config/GraphicsSettings.h"

#import "VideoCommon/VideoCommon.h"

#import "InternalResolutionCell.h"
#import "LocalizationUtil.h"

@interface InternalResolutionViewController ()

@end

@implementation InternalResolutionViewController {
  NSInteger _lastSelected;
  NSArray<NSString*>* _resolutions;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  NSMutableArray<NSString*>* resolutions = [[NSMutableArray alloc] init];
  
  // Hardcoded resolutions
  NSArray<NSString*>* hardcodedResolutions = @[
    DOLCoreLocalizedString(@"Auto (Multiple of 640x528)"),
    DOLCoreLocalizedString(@"Native (640x528)"),
    DOLCoreLocalizedString(@"2x Native (1280x1056) for 720p"),
    DOLCoreLocalizedString(@"3x Native (1920x1584) for 1080p"),
    DOLCoreLocalizedString(@"4x Native (2560x2112) for 1440p"),
    DOLCoreLocalizedString(@"5x Native (3200x2640)"),
    DOLCoreLocalizedString(@"6x Native (3840x3168) for 4K"),
    DOLCoreLocalizedString(@"7x Native (4480x3696)"),
    DOLCoreLocalizedString(@"8x Native (5120x4224) for 5K"),
    DOLCoreLocalizedString(@"9x Native (5760x4752)"),
    DOLCoreLocalizedString(@"10x Native (6400x5280)"),
    DOLCoreLocalizedString(@"11x Native (7040x5808)"),
    DOLCoreLocalizedString(@"12x Native (7680x6336) for 8K")
  ];
  
  [resolutions addObjectsFromArray:hardcodedResolutions];
  
  NSString* additionalResolution = DOLCoreLocalizedStringWithArgs(@"%1x Native (%2x%3)", @"d", @"d", @"d");
  
  const int current_efb_scale = Config::Get(Config::GFX_EFB_SCALE);
  const int max_efb_scale = std::max(current_efb_scale, Config::Get(Config::GFX_MAX_EFB_SCALE));
  
   for (int scale = (int)[hardcodedResolutions count]; scale <= max_efb_scale; scale++) {
     NSString* resolution = [NSString stringWithFormat:additionalResolution, scale, EFB_WIDTH * scale, EFB_HEIGHT * scale];
     [resolutions addObject:resolution];
   }
  
  _lastSelected = current_efb_scale;
  _resolutions = resolutions;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
  return [_resolutions count];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  InternalResolutionCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ResolutionCell" forIndexPath:indexPath];
  cell.resolutionLabel.text = [_resolutions objectAtIndex:indexPath.row];
  
  if (indexPath.row == _lastSelected) {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  } else {
    cell.accessoryType = UITableViewCellAccessoryNone;
  }
  
  return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  if (_lastSelected != indexPath.row) {
    Config::SetBaseOrCurrent(Config::GFX_EFB_SCALE, (int)indexPath.row);

    InternalResolutionCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    InternalResolutionCell* oldCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_lastSelected inSection:0]];
    oldCell.accessoryType = UITableViewCellAccessoryNone;
    
    _lastSelected = indexPath.row;
  }
  
  [tableView deselectRowAtIndexPath:indexPath animated:true];
}

@end
