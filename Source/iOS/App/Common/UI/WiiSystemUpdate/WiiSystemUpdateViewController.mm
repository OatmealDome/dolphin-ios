// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "WiiSystemUpdateViewController.h"

#import "Core/WiiUtils.h"

#import "DiscIO/NANDImporter.h"

#import "FoundationStringUtil.h"
#import "LocalizationUtil.h"

@interface WiiSystemUpdateViewController ()

@end

@implementation WiiSystemUpdateViewController {
  bool _hasStarted;
  bool _isCancelled;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
  // Auto-sleep off
  [[UIApplication sharedApplication] setIdleTimerDisabled:true];
  
  [super viewDidAppear:animated];
  
  if (_hasStarted) {
    return;
  }
  
  _hasStarted = true;
  
  WiiSystemUpdateViewController* thisPtr = self;
  WiiUtils::UpdateCallback callback = [thisPtr](size_t processed, size_t total, u64 titleId) {
    dispatch_sync(dispatch_get_main_queue(), ^{
      if (thisPtr->_isCancelled) {
        return;
      }
      
      [thisPtr.progressBar setProgress:(float)processed / (float)total];
      
      NSString* statusFormat = DOLCoreLocalizedStringWithArgs(@"Updating title %1...\nThis can take a while.", @"016llx");
      [thisPtr.statusLabel setText:[NSString stringWithFormat:statusFormat, titleId]];
    });
    
    return !thisPtr->_isCancelled;
  };
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    WiiUtils::UpdateResult result;
    if (self.isOnlineUpdate) {
      result = WiiUtils::DoOnlineUpdate(callback, FoundationToCppString(self.updateSource));
    } else {
      result = WiiUtils::DoDiscUpdate(callback, FoundationToCppString(self.updateSource));
    }
    
    if (result == WiiUtils::UpdateResult::Succeeded || result == WiiUtils::UpdateResult::AlreadyUpToDate) {
      DiscIO::NANDImporter().ExtractCertificates();
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
      switch (result)
      {
      case WiiUtils::UpdateResult::Succeeded:
        [self showAlertWithTitle:@"Update completed"
                         message:@"The emulated Wii console has been updated."];
          
        break;
      case WiiUtils::UpdateResult::AlreadyUpToDate:
        [self showAlertWithTitle:@"Update completed"
                         message:@"The emulated Wii console is already up-to-date."];
          
        break;
      case WiiUtils::UpdateResult::ServerFailed:
        [self showAlertWithTitle:@"Update failed"
                         message:@"Could not download update information from Nintendo. "
                                   "Please check your Internet connection and try again."];
        break;
      case WiiUtils::UpdateResult::DownloadFailed:
        [self showAlertWithTitle:@"Update failed"
                         message:@"Could not download update files from Nintendo. "
                                   "Please check your Internet connection and try again."];
        break;
      case WiiUtils::UpdateResult::ImportFailed:
        [self showAlertWithTitle:@"Update failed"
                         message:@"Could not install an update to the Wii system memory. "
                                   "Please refer to logs for more information."];
        break;
      case WiiUtils::UpdateResult::Cancelled:
        [self showAlertWithTitle:@"Update cancelled"
                         message:@"The update has been cancelled. It is strongly recommended to "
                                   "finish it in order to avoid inconsistent system software versions."];
        break;
      case WiiUtils::UpdateResult::RegionMismatch:
        [self showAlertWithTitle:@"Update failed"
                         message:@"The game's region does not match your console's. "
                                   "To avoid issues with the system menu, it is not possible "
                                   "to update the emulated console using this disc."];
        break;
      case WiiUtils::UpdateResult::MissingUpdatePartition:
      case WiiUtils::UpdateResult::DiscReadFailed:
        [self showAlertWithTitle:@"Update failed"
                         message:@"The game disc does not contain any usable "
                                   "update information."];
        break;
      case WiiUtils::UpdateResult::NumberOfEntries:
        break;
      }
    });
  });
}

- (void)viewWillDisappear:(BOOL)animated {
  // Auto-sleep on
  [[UIApplication sharedApplication] setIdleTimerDisabled:false];
}

- (IBAction)cancelPressed:(id)sender {
  _isCancelled = true;
  
  self.progressBar.trackTintColor = UIColor.systemRedColor;
  self.progressBar.progress = 1.0f;
  
  self.statusLabel.text = DOLCoreLocalizedString(@"Finishing the update...\nThis can take a while.");
  
  self.cancelButton.enabled = false;
}

- (void)showAlertWithTitle:(NSString*)title message:(NSString*)message {
  UIAlertController* alert = [UIAlertController alertControllerWithTitle:DOLCoreLocalizedString(title) message:DOLCoreLocalizedString(message) preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction*) {
    [self dismissViewControllerAnimated:true completion:nil];
  }]];
   
  [self presentViewController:alert animated:true completion:nil];
}

@end
