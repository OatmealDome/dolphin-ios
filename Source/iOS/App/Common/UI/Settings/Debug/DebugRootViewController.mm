// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "DebugRootViewController.h"

#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

#import "Core/Config/MainSettings.h"

#import "Swift.h"

#import "FastmemManager.h"
#import "JitManager.h"
#import "VirtualMFiControllerManager.h"

@interface DebugRootViewController () <UIDocumentPickerDelegate>

@end

@implementation DebugRootViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.fastmemSwitch.on = Config::Get(Config::MAIN_FASTMEM);
  self.fastmemSwitch.enabled = [FastmemManager shared].fastmemAvailable;
  [self.fastmemSwitch addValueChangedTarget:self action:@selector(fastmemChanged)];
  
  self.syncOnIdleSkipSwitch.on = Config::Get(Config::MAIN_SYNC_ON_SKIP_IDLE);
  [self.syncOnIdleSkipSwitch addValueChangedTarget:self action:@selector(syncOnIdleSkipChanged)];
  
  self.mfiSwitch.on = [VirtualMFiControllerManager shared].shouldConnectController;
  [self.mfiSwitch addValueChangedTarget:self action:@selector(mfiChanged)];

  self.selfEnableJitSwitch.on = [StikJITManager shared].selfEnableJitEnabled;
  [self.selfEnableJitSwitch addValueChangedTarget:self action:@selector(selfEnableJitChanged)];

  if (@available(iOS 17.4, *)) {
  } else {
    self.selfEnableJitSwitch.on = false;
    self.selfEnableJitSwitch.enabled = false;
  }

  self.importPairingFileStatusLabel.text = [StikJITManager shared].pairingFileDisplayName;

  [self refreshDDIStatus];

  self.userFolderPathLabel.text = [UserFolderUtil getUserFolder];
  
  if ([JitManager shared].acquiredJit)
  {
    NSString* jitType;
    
    if (@available(iOS 26, *))
    {
      if ([JitManager shared].deviceHasTxm)
      {
        jitType = @"TXM";
      }
      else
      {
        jitType = @"No TXM";
      }
    }
    else
    {
      jitType = @"Legacy";
    }
    
    self.jitStatusLabel.text = [NSString stringWithFormat:@"Acquired (%@)", jitType];
  }
  else
  {
    self.jitStatusLabel.text = @"Not Acquired";
  }
  
  NSString* jitError = [JitManager shared].acquisitionError;
  self.jitErrorLabel.text = jitError != nil ? jitError : @"(none)";
  
  self.fastmemStatusLabel.text = [FastmemManager shared].fastmemAvailable ? @"Available" : @"Not Available";
  
  NSInteger launchTimes = [[NSUserDefaults standardUserDefaults] integerForKey:@"launch_times"];
  self.launchTimesLabel.text = [NSString stringWithFormat:@"%tu", launchTimes];
}

- (void)fastmemChanged {
  Config::SetBaseOrCurrent(Config::MAIN_FASTMEM, self.fastmemSwitch.on);
}

- (void)syncOnIdleSkipChanged {
  Config::SetBaseOrCurrent(Config::MAIN_SYNC_ON_SKIP_IDLE, self.syncOnIdleSkipSwitch.on);
}

- (void)mfiChanged {
  [VirtualMFiControllerManager shared].shouldConnectController = self.mfiSwitch.on;
}

- (void)selfEnableJitChanged {
  [StikJITManager shared].selfEnableJitEnabled = self.selfEnableJitSwitch.on;

  [self.tableView beginUpdates];
  [self.tableView endUpdates];

  if (self.selfEnableJitSwitch.on) {
    [self refreshDDIStatus];
  }
}

- (void)refreshDDIStatus {
  self.ddiMounterStatusLabel.text = @"Checking...";

  __weak DebugRootViewController* weakSelf = self;
  [[DDIManager shared] checkStatusWithCompletion:^(NSString* status) {
    DebugRootViewController* strongSelf = weakSelf;
    if (strongSelf == nil) {
      return;
    }

    strongSelf.ddiMounterStatusLabel.text = status;
  }];
}

- (void)confirmDeleteDDI {
  UIAlertController* confirmAlert = [UIAlertController alertControllerWithTitle:@"Delete Developer Disk Image" message:@"This will delete the cached Developer Disk Image. It will be downloaded and mounted again the next time you enable JIT with StikJIT." preferredStyle:UIAlertControllerStyleAlert];

  [confirmAlert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

  __weak DebugRootViewController* weakSelf = self;
  [confirmAlert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action) {
    [[DDIManager shared] deleteCachedDDI];
    [weakSelf refreshDDIStatus];
  }]];

  [self presentViewController:confirmAlert animated:true completion:nil];
}

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
#ifndef DEBUG
  if (section == 1 || section == 2) {
    return CGFLOAT_MIN;
  }
#endif

  return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section {
#ifndef DEBUG
  if (section == 1 || section == 2) {
    return CGFLOAT_MIN;
  }
#endif

  return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
  if (indexPath.section == 3 && (indexPath.row == 4 || indexPath.row == 5) && !self.selfEnableJitSwitch.on) {
    return CGFLOAT_MIN;
  }

#ifndef DEBUG
  if (indexPath.section == 1 || indexPath.section == 2) {
    return CGFLOAT_MIN;
  }
#endif

  return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  if (indexPath.section == 2 && indexPath.row == 0) { // Reset Launch Times
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"launch_times"];

    UIAlertController* launchAlert = [UIAlertController alertControllerWithTitle:@"Reset" message:@"launch_times was reset to 0." preferredStyle:UIAlertControllerStyleAlert];

    [launchAlert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
      //
    }]];

    [self presentViewController:launchAlert animated:true completion:nil];
  } else if (indexPath.section == 2 && indexPath.row == 1) { // Force Start Motion
#if TARGET_OS_IOS
    TCDeviceMotion* sharedMotion = [TCDeviceMotion shared];
    [sharedMotion setPort:4];
    [sharedMotion setMotionEnabled:true];
#endif
  } else if (indexPath.section == 3 && indexPath.row == 4) {
    NSArray<UTType*>* contentTypes = @[[UTType typeWithIdentifier:@"public.data"]];

    UIDocumentPickerViewController* picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:contentTypes];
    picker.delegate = self;

    [self presentViewController:picker animated:true completion:nil];
  } else if (indexPath.section == 3 && indexPath.row == 5) {
    [self confirmDeleteDDI];
  }

  [self.tableView deselectRowAtIndexPath:indexPath animated:true];
}

- (void)documentPicker:(UIDocumentPickerViewController*)controller didPickDocumentsAtURLs:(NSArray<NSURL*>*)urls {
  NSURL* url = urls.firstObject;

  if (url == nil) {
    return;
  }

  if (![url startAccessingSecurityScopedResource]) {
    return;
  }

  NSError* error = nil;
  [[StikJITManager shared] importPairingFile:url error:&error];

  [url stopAccessingSecurityScopedResource];

  if (error != nil) {
    UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:@"Error" message:[NSString stringWithFormat:@"Failed to import pairing file: %@", [error localizedDescription]] preferredStyle:UIAlertControllerStyleAlert];

    [errorAlert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];

    [self presentViewController:errorAlert animated:true completion:nil];

    return;
  }

  self.importPairingFileStatusLabel.text = [StikJITManager shared].pairingFileDisplayName;
}

@end
