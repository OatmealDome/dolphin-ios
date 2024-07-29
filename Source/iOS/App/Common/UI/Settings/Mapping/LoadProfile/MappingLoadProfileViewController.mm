// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "MappingLoadProfileViewController.h"

#import <string>
#import <vector>

#import "Common/FileSearch.h"
#import "Common/FileUtil.h"
#import "Common/IniFile.h"

#import "InputCommon/ControllerEmu/ControllerEmu.h"
#import "InputCommon/InputConfig.h"

#import "FoundationStringUtil.h"
#import "LocalizationUtil.h"
#import "MappingLoadProfileIniCell.h"
#import "MappingLoadProfileViewControllerDelegate.h"

struct Profile {
  std::string path;
  std::string name;
  bool isStock;
};

@interface MappingLoadProfileViewController ()

@end

@implementation MappingLoadProfileViewController {
  std::vector<Profile> _profiles;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  _profiles.clear();
  
  const std::string profilesPath = File::GetUserPath(D_CONFIG_IDX) + "Profiles/" + self.inputConfig->GetProfileKey();
  for (const auto& filename : Common::DoFileSearch({profilesPath}, {".ini"}))
  {
    std::string basename;
    SplitPath(filename, nullptr, &basename, nullptr);
    
    // Ignore files with an empty name to avoid multiple problems
    if (!basename.empty()) {
      _profiles.push_back({filename, basename, false});
    }
  }

  const std::string builtInPath = File::GetSysDirectory() + "Profiles/" + self.inputConfig->GetProfileDirectoryName();
  for (const auto& filename : Common::DoFileSearch({builtInPath}, {".ini"}))
  {
    std::string basename;
    SplitPath(filename, nullptr, &basename, nullptr);
    
    // We can't connect real Wii Remotes on iOS, so don't show this profile.
    if (basename == "Wii Remote with MotionPlus Pointing") {
      continue;
    }
    
    // Don't show the Touchscreen profile if it exists
    if (basename == "Touchscreen" && self.filterTouchscreen) {
      continue;
    }
    
    if (!basename.empty()) {
      _profiles.push_back({filename, basename, true});
    }
  }
  
  [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
  return _profiles.size();
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  MappingLoadProfileIniCell* iniCell = [tableView dequeueReusableCellWithIdentifier:@"IniCell" forIndexPath:indexPath];
  
  const auto& profile = _profiles[indexPath.row];
  
  NSString* profileName = CppToFoundationString(profile.name);
  
  if (profile.isStock) {
    iniCell.nameLabel.text = [NSString stringWithFormat:DOLCoreLocalizedStringWithArgs(@"%1 (Stock)", @"@"), profileName];
  } else {
    iniCell.nameLabel.text = profileName;
  }
  
  return iniCell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  const auto& profile = _profiles[indexPath.row];
  
  Common::IniFile ini;
  ini.Load(profile.path);

  _emulatedController->LoadConfig(ini.GetOrCreateSection("Profile"));
  _emulatedController->UpdateReferences(g_controller_interface);
  
  [self.delegate profileDidLoad:self];
  
  // TODO: Localization
  UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Loaded" message:[NSString stringWithFormat:@"The profile \"%@\" was loaded.", CppToFoundationString(profile.name)] preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction*) {
    [self.navigationController dismissViewControllerAnimated:true completion: nil];
  }]];
  
  [self presentViewController:alert animated:true completion:nil];
  
  [tableView deselectRowAtIndexPath:indexPath animated:true];
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath {
  return !_profiles[indexPath.row].isStock;
}

// Override to support editing the table view.
- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    File::Delete(_profiles[indexPath.row].path);
    
    _profiles.erase(_profiles.begin() + indexPath.row);
    
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
  }
}

- (IBAction)cancelPressed:(id)sender {
  [self.navigationController dismissViewControllerAnimated:true completion: nil];
}

@end
