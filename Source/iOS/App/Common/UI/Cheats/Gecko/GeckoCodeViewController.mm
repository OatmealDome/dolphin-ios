// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "GeckoCodeViewController.h"

#import <vector>

#import "Common/FileUtil.h"
#import "Common/IniFile.h"

#import "Core/ConfigManager.h"
#import "Core/GeckoCode.h"
#import "Core/GeckoCodeConfig.h"

#import "DOLSwitch.h"
#import "FoundationStringUtil.h"
#import "GeckoCodeEditViewController.h"
#import "GeckoCodeEditViewControllerDelegate.h"
#import "LocalizationUtil.h"
#import "Swift.h"

@interface GeckoCodeViewController () <GeckoCodeEditViewControllerDelegate>

@end

@implementation GeckoCodeViewController {
  std::vector<Gecko::GeckoCode> _codes;
  Gecko::GeckoCode _newCode;
  Gecko::GeckoCode* _editTargetCode;
  bool _editTargetIsNew;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.navigationItem.rightBarButtonItem = self.editButtonItem;
  
  Common::IniFile gameIniLocal;
  gameIniLocal.Load(File::GetUserPath(D_GAMESETTINGS_IDX) + self.gameId + ".ini");

  const Common::IniFile gameIniDefault = SConfig::LoadDefaultGameIni(self.gameId, self.revision);
  
  _codes = Gecko::LoadCodes(gameIniDefault, gameIniLocal);
}

- (void)saveCodes {
  const auto iniPath = std::string(File::GetUserPath(D_GAMESETTINGS_IDX)).append(self.gameId).append(".ini");

  Common::IniFile gameIniLocal;
  gameIniLocal.Load(iniPath);
  Gecko::SaveCodes(gameIniLocal, self->_codes);
  gameIniLocal.Save(iniPath);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
  return 2;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
  return section == 0 ? 2 : self->_codes.size();
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  if (indexPath.section == 0) {
    if (indexPath.row == 0) {
      // Add cell
      return [tableView dequeueReusableCellWithIdentifier:@"addCell" forIndexPath:indexPath];
    } else {
      // Download cell
      return [tableView dequeueReusableCellWithIdentifier:@"downloadCell" forIndexPath:indexPath];
    }
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
    if (indexPath.row == 0) {
      self->_newCode = Gecko::GeckoCode();
      self->_editTargetCode = &self->_newCode;
      self->_editTargetIsNew = true;
      
      [self performSegueWithIdentifier:@"edit" sender:nil];
    } else {
      // TODO: Localization
      UIAlertController* downloadAlert = [UIAlertController alertControllerWithTitle:@"Downloading..." message:nil preferredStyle:UIAlertControllerStyleAlert];
      
      [self presentViewController:downloadAlert animated:true completion:^{
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
          void (^showResult)(NSString*, NSString*) = ^void(NSString* title, NSString* text) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [self.tableView reloadData];
              
              [self dismissViewControllerAnimated:true completion:^{
                UIAlertController* resultAlert = [UIAlertController alertControllerWithTitle:title message:text preferredStyle:UIAlertControllerStyleAlert];
                [resultAlert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"OK") style:UIAlertActionStyleDefault handler:nil]];
                
                [self presentViewController:resultAlert animated:true completion:nil];
              }];
            });
          };
          
          bool success;
          std::vector<Gecko::GeckoCode> downloadedCodes = Gecko::DownloadCodes(self.gametdbId, &success);

          if (!success) {
            showResult(DOLCoreLocalizedString(@"Error"), DOLCoreLocalizedString(@"Failed to download codes."));
            return;
          }

          if (downloadedCodes.empty()) {
            showResult(DOLCoreLocalizedString(@"Error"), DOLCoreLocalizedString(@"File contained no codes."));
            return;
          }

          size_t addedCount = 0;

          for (const auto& code : downloadedCodes) {
            auto it = std::find(self->_codes.begin(), self->_codes.end(), code);

            if (it == self->_codes.end()) {
              self->_codes.push_back(code);
              addedCount++;
            }
          }
          
          [self saveCodes];
          
          NSString* resultTextFormat = DOLCoreLocalizedStringWithArgs(@"Downloaded %1 codes. (added %2)", @"d", @"d");
          NSString* resultText = [NSString stringWithFormat:resultTextFormat, downloadedCodes.size(), addedCount];
          
          showResult(DOLCoreLocalizedString(@"Download complete"), resultText);
        });
      }];
    }
  } else {
    self->_editTargetCode = &self->_codes[indexPath.row];
    self->_editTargetIsNew = false;
    
    [self performSegueWithIdentifier:@"edit" sender:nil];
  }
  
  [self.tableView deselectRowAtIndexPath:indexPath animated:true];
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath {
  return indexPath.section == 1;
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
    GeckoCodeEditViewController* editController = segue.destinationViewController;
    editController.delegate = self;
    editController.code = self->_editTargetCode;
  }
}

- (void)userDidSaveCode:(GeckoCodeEditViewController*)viewController {
  if (self->_editTargetIsNew) {
    self->_codes.push_back(std::move(self->_newCode));
  }
  
  [self saveCodes];
  
  [self.tableView reloadData];
}

@end
