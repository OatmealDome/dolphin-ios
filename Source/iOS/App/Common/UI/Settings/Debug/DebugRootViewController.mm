// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "DebugRootViewController.h"

#import "Core/Config/MainSettings.h"

#import "Swift.h"

#import "FastmemManager.h"
#import "JitManager.h"
#import "VirtualMFiControllerManager.h"

@interface DebugRootViewController ()

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
  
  self.userFolderPathLabel.text = [UserFolderUtil getUserFolder];
  self.jitStatusLabel.text = [JitManager shared].acquiredJit ? @"Acquired" : @"Not Acquired";
  
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

#ifndef DEBUG

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
  if (section == 1 || section == 2) {
    return CGFLOAT_MIN;
  }
  
  return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section {
  if (section == 1 || section == 2) {
    return CGFLOAT_MIN;
  }
  
  return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
  if (indexPath.section == 1 || indexPath.section == 2) {
    return CGFLOAT_MIN;
  }
  
  return UITableViewAutomaticDimension;
}

#endif

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
  }
  
  [self.tableView deselectRowAtIndexPath:indexPath animated:true];
}

@end
