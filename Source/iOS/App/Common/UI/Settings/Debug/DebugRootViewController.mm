// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "DebugRootViewController.h"

#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

#include <cstdlib>

#import "Core/Config/MainSettings.h"

#import "Swift.h"

#import "FastmemManager.h"
#import "JitManager.h"
#import "JitManager+PTrace.h"
#import "VirtualMFiControllerManager.h"

@interface DebugRootViewController () <UIDocumentPickerDelegate>

@property(nonatomic, copy) NSString* jitLaunchModeButtonTitle;

- (void)applyJITLaunchModeButtonConfiguration:(UIButton*)button API_AVAILABLE(ios(15.0));

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

  self.forceJitScriptSwitch.on = [StikJITManager shared].forceJITScriptEnabled;
  [self.forceJitScriptSwitch addValueChangedTarget:self action:@selector(forceJitScriptChanged)];
  self.jitLaunchModeButton.showsMenuAsPrimaryAction = true;
  if (@available(iOS 15.0, *)) {
    self.jitLaunchModeButton.changesSelectionAsPrimaryAction = false;
    __weak DebugRootViewController* weakSelf = self;
    self.jitLaunchModeButton.configurationUpdateHandler = ^(UIButton* button) {
      [weakSelf applyJITLaunchModeButtonConfiguration:button];
    };
  }

  if (@available(iOS 17.4, *)) {
  } else {
    [StikJITManager shared].jitLaunchMode = JITLaunchModeWaitForDebugger;
  }

  [self refreshJITLaunchMode];

  [self refreshPreparationStatus];

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

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self refreshJITLaunchMode];
  [self refreshPreparationStatus];
  if ([StikJITManager shared].jitLaunchMode == JITLaunchModeBuiltInStikJIT) {
    [self detectTXM];
  }
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];

  BOOL isLeavingSettings = self.isMovingFromParentViewController || self.isBeingDismissed || self.navigationController.isBeingDismissed;
  if (isLeavingSettings && [StikJITManager shared].jitLaunchMode == JITLaunchModeBuiltInStikJIT && ![StikJITManager shared].hasPairingFile) {
    [StikJITManager shared].jitLaunchMode = JITLaunchModeWaitForDebugger;
  }
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

- (void)refreshJITLaunchMode {
  NSString* selectedTitle;
  switch ([StikJITManager shared].jitLaunchMode) {
  case JITLaunchModeExternalStikDebug:
    selectedTitle = @"External StikDebug";
    self.jitLaunchModeInfoLabel.text = @"Opens StikDebug to enable JIT when you launch a game.";
    break;
  case JITLaunchModeBuiltInStikJIT:
    selectedTitle = @"Built-in StikJIT";
    self.jitLaunchModeInfoLabel.text = @"Before launching a game, connect to LocalDevVPN, then connect to Wi-Fi or enable Airplane Mode. Import a pairing file to use Built-in StikJIT; otherwise, DolphiniOS uses Wait for Debugger.";
    break;
  case JITLaunchModeWaitForDebugger:
  default:
    selectedTitle = @"Wait for Debugger";
    self.jitLaunchModeInfoLabel.text = @"Waits for you to enable JIT before starting the game.";
    break;
  }

  [self refreshJITLaunchModeMenu];
  [self updateJITLaunchModeButtonWithTitle:selectedTitle];

  [self.tableView beginUpdates];
  [self.tableView endUpdates];
}

- (void)updateJITLaunchModeButtonWithTitle:(NSString*)title {
  self.jitLaunchModeButtonTitle = title;

  if (@available(iOS 15.0, *)) {
    [self.jitLaunchModeButton setNeedsUpdateConfiguration];
    [self.jitLaunchModeButton updateConfiguration];
    return;
  }

  UIFont* font = [UIFont systemFontOfSize:17 weight:UIFontWeightRegular];
  UIColor* color = UIColor.secondaryLabelColor;

  UIImageSymbolConfiguration* symbolConfiguration = [UIImageSymbolConfiguration configurationWithPointSize:11 weight:UIImageSymbolWeightSemibold];
  UIImage* image = [[UIImage systemImageNamed:@"chevron.up.chevron.down"] imageByApplyingSymbolConfiguration:symbolConfiguration]
    ?: [[UIImage systemImageNamed:@"chevron.down"] imageByApplyingSymbolConfiguration:symbolConfiguration];
  [self.jitLaunchModeButton setTitle:title forState:UIControlStateNormal];
  [self.jitLaunchModeButton setTitleColor:color forState:UIControlStateNormal];
  [self.jitLaunchModeButton setImage:image forState:UIControlStateNormal];
  self.jitLaunchModeButton.titleLabel.font = font;
  self.jitLaunchModeButton.titleLabel.numberOfLines = 1;
  self.jitLaunchModeButton.titleLabel.adjustsFontSizeToFitWidth = true;
  self.jitLaunchModeButton.titleLabel.minimumScaleFactor = 0.75;
  self.jitLaunchModeButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
  self.jitLaunchModeButton.tintColor = color;
  self.jitLaunchModeButton.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
  self.jitLaunchModeButton.imageEdgeInsets = UIEdgeInsetsMake(0, 8, 0, -8);
}

- (void)applyJITLaunchModeButtonConfiguration:(UIButton*)button {
  UIFont* font = [UIFont systemFontOfSize:17 weight:UIFontWeightRegular];
  UIColor* color = UIColor.secondaryLabelColor;
  UIButtonConfiguration* configuration = [UIButtonConfiguration plainButtonConfiguration];
  configuration.attributedTitle = [[NSAttributedString alloc] initWithString:self.jitLaunchModeButtonTitle ?: @"" attributes:@{
    NSFontAttributeName: font,
    NSForegroundColorAttributeName: color
  }];
  configuration.baseForegroundColor = color;
  configuration.contentInsets = NSDirectionalEdgeInsetsZero;
  configuration.titleLineBreakMode = NSLineBreakByTruncatingTail;

  if (@available(iOS 16.0, *)) {
    configuration.indicator = UIButtonConfigurationIndicatorPopup;
  } else {
    UIImageSymbolConfiguration* symbolConfiguration = [UIImageSymbolConfiguration configurationWithPointSize:11 weight:UIImageSymbolWeightSemibold];
    configuration.image = [[UIImage systemImageNamed:@"chevron.up.chevron.down"] imageByApplyingSymbolConfiguration:symbolConfiguration]
      ?: [[UIImage systemImageNamed:@"chevron.down"] imageByApplyingSymbolConfiguration:symbolConfiguration];
    configuration.imagePlacement = NSDirectionalRectEdgeTrailing;
    configuration.imagePadding = 8;
  }

  button.configuration = configuration;
  button.titleLabel.numberOfLines = 1;
  button.titleLabel.adjustsFontSizeToFitWidth = true;
  button.titleLabel.minimumScaleFactor = 0.75;
  button.titleLabel.allowsDefaultTighteningForTruncation = true;
}

- (void)refreshJITLaunchModeMenu {
  JITLaunchMode selectedMode = [StikJITManager shared].jitLaunchMode;
  __weak DebugRootViewController* weakSelf = self;

  UIAction* waitAction = [UIAction actionWithTitle:@"Wait for Debugger" image:nil identifier:nil handler:^(UIAction* action) {
    [weakSelf selectJITLaunchMode:JITLaunchModeWaitForDebugger];
  }];
  waitAction.state = selectedMode == JITLaunchModeWaitForDebugger ? UIMenuElementStateOn : UIMenuElementStateOff;

  UIAction* externalAction = [UIAction actionWithTitle:@"External StikDebug" image:nil identifier:nil handler:^(UIAction* action) {
    [weakSelf selectJITLaunchMode:JITLaunchModeExternalStikDebug];
  }];
  externalAction.state = selectedMode == JITLaunchModeExternalStikDebug ? UIMenuElementStateOn : UIMenuElementStateOff;

  UIAction* builtInAction = [UIAction actionWithTitle:@"Built-in StikJIT" image:nil identifier:nil handler:^(UIAction* action) {
    [weakSelf selectJITLaunchMode:JITLaunchModeBuiltInStikJIT];
  }];
  builtInAction.state = selectedMode == JITLaunchModeBuiltInStikJIT ? UIMenuElementStateOn : UIMenuElementStateOff;

  if (@available(iOS 17.4, *)) {
  } else {
    externalAction.attributes = UIMenuElementAttributesDisabled;
    builtInAction.attributes = UIMenuElementAttributesDisabled;
  }

  self.jitLaunchModeButton.menu = [UIMenu menuWithChildren:@[waitAction, externalAction, builtInAction]];
}

- (void)selectJITLaunchMode:(JITLaunchMode)mode {
  [StikJITManager shared].jitLaunchMode = mode;
  [self refreshJITLaunchMode];

  if ([self configureLiveContainerForJITLaunchMode:mode]) {
    return;
  }

  if (mode == JITLaunchModeBuiltInStikJIT) {
    [self refreshPreparationStatus];
    [self detectTXM];
  }
}

- (BOOL)configureLiveContainerForJITLaunchMode:(JITLaunchMode)mode {
  if (mode == JITLaunchModeWaitForDebugger || std::getenv("LC_HOME_PATH") == nullptr) {
    return NO;
  }

  BOOL useBundleID = mode == JITLaunchModeExternalStikDebug;
  NSString* key = useBundleID ? @"doUseLCBundleId" : @"helperProcessesSupport";
  NSString* setting = useBundleID ? @"Use LiveContainer’s Bundle ID" : @"Helper Process Support";
  NSURL* bundleURL = NSBundle.mainBundle.bundleURL;
  NSURL* settingsURL = [bundleURL URLByAppendingPathComponent:@"LCAppInfo.plist"];
  NSDictionary* currentSettings = [NSDictionary dictionaryWithContentsOfURL:settingsURL error:nullptr];
  if ([currentSettings[key] boolValue]) {
    return NO;
  }

  NSMutableDictionary* settings = [currentSettings mutableCopy];
  settings[key] = @YES;
  BOOL saved = NO;
  if (useBundleID) {
    NSURL* infoURL = [bundleURL URLByAppendingPathComponent:@"Info.plist"];
    NSMutableDictionary* info = [[NSDictionary dictionaryWithContentsOfURL:infoURL error:nullptr] mutableCopy];
    NSString* originalID = info[@"CFBundleIdentifier"];
    NSString* hostID = [[JitManager shared] signedApplicationBundleIdentifier];
    if (originalID.length > 0 && hostID.length > 0) {
      settings[@"LCOrignalBundleIdentifier"] = originalID;
      info[@"CFBundleIdentifier"] = hostID;
      if ([settings writeToURL:settingsURL error:nullptr]) {
        saved = [info writeToURL:infoURL error:nullptr];
        if (!saved) {
          [currentSettings writeToURL:settingsURL error:nullptr];
        }
      }
    }
  } else {
    saved = [settings writeToURL:settingsURL error:nullptr];
  }

  NSString* title = saved ? @"LiveContainer Setting Changed" : @"LiveContainer Setting Required";
  NSString* message = saved
      ? [NSString stringWithFormat:@"“%@” is enabled. Reopen DolphiniOS in LiveContainer after it closes.", setting]
      : [NSString stringWithFormat:@"Could not enable “%@”. Turn it on in LiveContainer’s settings for DolphiniOS, then reopen the app.", setting];
  UIAlertController* alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:saved ? @"Close App" : @"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
    if (saved) {
      std::exit(EXIT_SUCCESS);
    }
  }]];
  [self presentViewController:alert animated:true completion:nil];
  return YES;
}

- (void)forceJitScriptChanged {
  [StikJITManager shared].forceJITScriptEnabled = self.forceJitScriptSwitch.on;
}

- (void)refreshPreparationStatus {
  self.preparationStatusLabel.text = [DDIManager shared].preparationStatus;
  self.importPairingFileStatusLabel.text = [StikJITManager shared].pairingFileStatus;
  self.txmStatusLabel.text = [DDIManager shared].txmStatus;
}

- (void)detectTXM {
  self.txmStatusLabel.text = @"Detecting...";

  __weak DebugRootViewController* weakSelf = self;
  [[DDIManager shared] detectTXMWithCompletion:^{
    DebugRootViewController* strongSelf = weakSelf;
    if (strongSelf == nil) {
      return;
    }
    strongSelf.txmStatusLabel.text = [DDIManager shared].txmStatus;
  }];
}

- (void)prepareJIT {
  if (![[JitManager shared] hasGetTaskAllowEntitlement]) {
    UIAlertController* entitlementAlert = [UIAlertController alertControllerWithTitle:@"Not Ready" message:@"This installation does not have the get-task-allow entitlement. Reinstall DolphiniOS using a signing method that preserves this entitlement." preferredStyle:UIAlertControllerStyleAlert];
    [entitlementAlert addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:entitlementAlert animated:true completion:nil];
    return;
  }

  UIAlertController* progressAlert = [UIAlertController alertControllerWithTitle:@"Preparing JIT" message:@"Starting..." preferredStyle:UIAlertControllerStyleAlert];

  __weak DebugRootViewController* weakSelf = self;
  [self presentViewController:progressAlert animated:true completion:^{
    [[DDIManager shared] prepareDeviceWithProgress:^(double fraction, NSString* status) {
      NSString* message = status;
      if (fraction > 0 && fraction < 1) {
        message = [NSString stringWithFormat:@"%@ (%d%%)", status, (int)(fraction * 100)];
      }
      progressAlert.message = message;
    } completion:^(BOOL success, NSString* error) {
      DebugRootViewController* strongSelf = weakSelf;
      [strongSelf refreshPreparationStatus];

      if (success) {
        progressAlert.message = @"Ready";
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
          [progressAlert dismissViewControllerAnimated:true completion:nil];
        });
        return;
      }

      progressAlert.title = [DDIManager shared].preparationStatus.length > 0 ? [DDIManager shared].preparationStatus : @"Preparation Failed";
      progressAlert.message = error ?: @"Device preparation failed.";
      [progressAlert addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:nil]];
    }];
  }];
}

- (void)confirmResetDDI {
  UIAlertController* confirmAlert = [UIAlertController alertControllerWithTitle:@"Reset Developer Disk Image" message:@"This will delete the three cached Developer Disk Image files. They will be downloaded and mounted again the next time you prepare or enable JIT with StikJIT." preferredStyle:UIAlertControllerStyleAlert];

  [confirmAlert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

  __weak DebugRootViewController* weakSelf = self;
  [confirmAlert addAction:[UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action) {
    [[DDIManager shared] resetCachedDDIWithCompletion:^(BOOL success, NSString* error) {
      [weakSelf refreshPreparationStatus];
      if (!success) {
        UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:@"Error" message:error ?: @"Failed to reset the cached Developer Disk Image." preferredStyle:UIAlertControllerStyleAlert];
        [errorAlert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [weakSelf presentViewController:errorAlert animated:true completion:nil];
      }
    }];
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
  if (indexPath.section == 3 && indexPath.row == 4) {
    return UITableViewAutomaticDimension;
  }

  if (indexPath.section == 3 && indexPath.row >= 5 && indexPath.row <= 9 && [StikJITManager shared].jitLaunchMode != JITLaunchModeBuiltInStikJIT) {
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
  } else if (indexPath.section == 3 && indexPath.row == 5) {
    NSArray<UTType*>* contentTypes = @[[UTType typeWithIdentifier:@"public.data"]];

    UIDocumentPickerViewController* picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:contentTypes asCopy:YES];
    picker.delegate = self;

    [self presentViewController:picker animated:true completion:nil];
  } else if (indexPath.section == 3 && indexPath.row == 6) {
    [self prepareJIT];
  } else if (indexPath.section == 3 && indexPath.row == 9) {
    [self confirmResetDDI];
  }

  [self.tableView deselectRowAtIndexPath:indexPath animated:true];
}

- (void)documentPicker:(UIDocumentPickerViewController*)controller didPickDocumentsAtURLs:(NSArray<NSURL*>*)urls {
  NSURL* url = urls.firstObject;

  if (url == nil) {
    return;
  }

  BOOL accessingSecurityScopedResource = [url startAccessingSecurityScopedResource];

  NSError* error = nil;
  [[StikJITManager shared] importPairingFile:url error:&error];

  if (accessingSecurityScopedResource) {
    [url stopAccessingSecurityScopedResource];
  }

  [[DDIManager shared] invalidateReadiness];
  [self refreshPreparationStatus];

  if (error != nil) {
    UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:@"Error" message:[NSString stringWithFormat:@"Failed to import pairing file: %@", [error localizedDescription]] preferredStyle:UIAlertControllerStyleAlert];

    [errorAlert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];

    [self presentViewController:errorAlert animated:true completion:nil];

    return;
  }
}

@end
