// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "ActionReplayCodeViewController.h"

#import "Common/FileUtil.h"
#import "Common/IniFile.h"

#import "Core/ActionReplay.h"
#import "Core/ConfigManager.h"

#import "ActionReplayCodeEditViewController.h"
#import "ActionReplayCodeEditViewControllerDelegate.h"
#import "DOLSwitch.h"
#import "FoundationStringUtil.h"
#import "Swift.h"

@interface ActionReplayCodeViewController () <ActionReplayCodeEditViewControllerDelegate>

@end

@implementation ActionReplayCodeViewController {
  std::vector<ActionReplay::ARCode> _codes;
  ActionReplay::ARCode _newCode;
  ActionReplay::ARCode* _editTargetCode;
  bool _editTargetIsNew;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.navigationItem.rightBarButtonItem = self.editButtonItem;
  
  Common::IniFile gameIniLocal;
  gameIniLocal.Load(File::GetUserPath(D_GAMESETTINGS_IDX) + self.gameId + ".ini");

  const Common::IniFile gameIniDefault = SConfig::LoadDefaultGameIni(self.gameId, self.revision);
  
  self->_codes = ActionReplay::LoadCodes(gameIniDefault, gameIniLocal);
}

- (void)saveCodes {
  const auto iniPath = std::string(File::GetUserPath(D_GAMESETTINGS_IDX)).append(self.gameId).append(".ini");

  Common::IniFile gameIniLocal;
  gameIniLocal.Load(iniPath);
  ActionReplay::SaveCodes(&gameIniLocal, self->_codes);
  gameIniLocal.Save(iniPath);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
  return 2;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
  return section == 0 ? 1 : self->_codes.size();
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  if (indexPath.section == 0) {
    return [tableView dequeueReusableCellWithIdentifier:@"addCell" forIndexPath:indexPath];
  } else {
    const auto& code = self->_codes[indexPath.row];
    
    CheatCell* cell = [tableView dequeueReusableCellWithIdentifier:@"cheatCell" forIndexPath:indexPath];
    
    [cell.nameLabel setText:CppToFoundationString(code.name)];
    
    [cell.enabledSwitch setOn:code.enabled];
    [cell.enabledSwitch setTag:indexPath.row];
    
    return cell;
  }
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  if (indexPath.section == 0) {
    self->_newCode = ActionReplay::ARCode();
    self->_editTargetCode = &self->_newCode;
    self->_editTargetIsNew = true;
  } else {
    self->_editTargetCode = &self->_codes[indexPath.row];
    
    if (!self->_editTargetCode->user_defined) {
      self->_newCode = *_editTargetCode;
      self->_editTargetCode = &self->_newCode;
      self->_editTargetIsNew = true;
    } else {
      self->_editTargetIsNew = false;
    }
  }
  
  [self performSegueWithIdentifier:@"edit" sender:nil];
  
  [self.tableView deselectRowAtIndexPath:indexPath animated:true];
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath {
  if (indexPath.section == 0) {
    return false;
  }
  
  return self->_codes[indexPath.row].user_defined;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    self->_codes.erase(self->_codes.begin() + indexPath.row);
    
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    
    [self saveCodes];
  }
}

- (IBAction)codeEnabledChanged:(DOLSwitch*)sender {
  self->_codes[sender.tag].enabled = sender.on;
  
  [self saveCodes];
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
  if ([segue.identifier isEqualToString:@"edit"]) {
    ActionReplayCodeEditViewController* editController = segue.destinationViewController;
    editController.delegate = self;
    editController.code = self->_editTargetCode;
  }
}

- (void)userDidSaveCode:(ActionReplayCodeEditViewController*)viewController {
  if (self->_editTargetIsNew) {
    self->_codes.push_back(std::move(self->_newCode));
  }
  
  [self saveCodes];
  
  [self.tableView reloadData];
}

@end
