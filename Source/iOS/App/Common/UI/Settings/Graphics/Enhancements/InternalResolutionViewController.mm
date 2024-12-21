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
    DOLCoreLocalizedString(@"Native (640x528)")
  ];
  
  NSArray<NSString*>* extraOptions = @[
    DOLCoreLocalizedString(@"720p"),
    DOLCoreLocalizedString(@"1080p"),
    DOLCoreLocalizedString(@"1440p"),
    @"",
    DOLCoreLocalizedString(@"4K"),
    @"",
    DOLCoreLocalizedString(@"5K"),
    @"",
    @"",
    @"",
    DOLCoreLocalizedString(@"8K")
  ];
  
  [resolutions addObjectsFromArray:hardcodedResolutions];
  
  NSString* additionalResolutionWithExtra = DOLCoreLocalizedStringWithArgs(@"%1x Native (%2x%3) for %4", @"d", @"d", @"d", @"@");
  NSString* additionalResolutionWithoutExtra = DOLCoreLocalizedStringWithArgs(@"%1x Native (%2x%3)", @"d", @"d", @"d");
  
  const int current_efb_scale = Config::Get(Config::GFX_EFB_SCALE);
  const int max_efb_scale = std::max(current_efb_scale, Config::Get(Config::GFX_MAX_EFB_SCALE));
  
   for (int scale = (int)[hardcodedResolutions count]; scale <= max_efb_scale; scale++) {
     const int extraIndex = scale - (int)hardcodedResolutions.count;
     
     NSString* extraOption;
     
     if (extraOptions.count > extraIndex) {
       extraOption = extraOptions[extraIndex];
     } else {
       extraOption = @"";
     }
     
     NSString* format;
     
     if ([extraOption isEqualToString:@""]) {
       format = additionalResolutionWithoutExtra;
     } else {
       format = additionalResolutionWithExtra;
     }
     
     NSString* resolution = [NSString stringWithFormat:format, scale, EFB_WIDTH * scale, EFB_HEIGHT * scale, extraOption];
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
