// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "GraphicsShaderModeViewController.h"

#import "Core/Config/GraphicsSettings.h"

@interface GraphicsShaderModeViewController ()

@end

@implementation GraphicsShaderModeViewController {
  NSInteger _lastSelected;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  _lastSelected = (NSInteger)Config::Get(Config::GFX_SHADER_COMPILATION_MODE);
  
  UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_lastSelected inSection:0]];
  [cell setAccessoryType:UITableViewCellAccessoryCheckmark];

}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  if (_lastSelected != indexPath.row) {
    Config::SetBaseOrCurrent(Config::GFX_SHADER_COMPILATION_MODE, (ShaderCompilationMode)indexPath.row);
    
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    UITableViewCell* oldCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_lastSelected inSection:0]];
    oldCell.accessoryType = UITableViewCellAccessoryNone;
    
    _lastSelected = indexPath.row;
  }
  
  [tableView deselectRowAtIndexPath:indexPath animated:true];
}

- (IBAction)specializedHelpPressed:(id)sender {
  [self showHelpWithLocalizable:@"Ubershaders are never used. Stuttering will occur during shader "
                                "compilation, but GPU demands are low.<br><br>Recommended for low-end hardware. "
                                "<br><br><dolphin_emphasis>If unsure, select this mode.</dolphin_emphasis>"];
}

- (IBAction)exclusiveHelpPressed:(id)sender {
  [self showHelpWithLocalizable:@"Ubershaders will always be used. Provides a near stutter-free experience at the cost of "
                                "very high GPU performance requirements.<br><br><dolphin_emphasis>Don't use this unless you "
                                "encountered stuttering with Hybrid Ubershaders and have a very powerful "
                                "GPU.</dolphin_emphasis>"];
}

- (IBAction)hybridHelpPressed:(id)sender {
  [self showHelpWithLocalizable:@"Ubershaders will be used to prevent stuttering during shader compilation, but "
                                "specialized shaders will be used when they will not cause stuttering.<br><br>In the "
                                "best case it eliminates shader compilation stuttering while having minimal "
                                "performance impact, but results depend on video driver behavior."];
}

- (IBAction)skipHelpPressed:(id)sender {
  [self showHelpWithLocalizable:@"Prevents shader compilation stuttering by not rendering waiting objects. Can work in "
                                "scenarios where Ubershaders doesn't, at the cost of introducing visual glitches and broken "
                                "effects.<br><br><dolphin_emphasis>Not recommended, only use if the other "
                                "options give poor results.</dolphin_emphasis>"];
}

@end
