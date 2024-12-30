// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "ImportFileManager.h"

#import "Swift.h"

#import "GameFileCacheManager.h"
#import "LocalizationUtil.h"
#import "MainSceneCoordinator.h"

@implementation ImportFileManager {
  UIWindow* _window;
}

+ (ImportFileManager*)shared {
  static ImportFileManager* sharedInstance = nil;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });

  return sharedInstance;
}

- (void)showWindowOnScene:(UIWindowScene*)scene {
  self->_window = [[UIWindow alloc] initWithWindowScene:scene];
  self->_window.frame = [UIScreen mainScreen].bounds;
  self->_window.rootViewController = [[UIViewController alloc] init];
  self->_window.windowLevel = UIWindowLevelAlert;
  
  UIWindow* topWindow = scene.windows.lastObject;
  self->_window.windowLevel = topWindow.windowLevel + 1;
  
  [self->_window makeKeyAndVisible];
}

- (void)hideWindow {
  [self->_window setHidden:true];
  
  self->_window = nil;
}

- (void)presentViewControllerOnWindow:(UIViewController*)controller {
  [self->_window.rootViewController presentViewController:controller animated:true completion:nil];
}

- (void)importFileAtUrl:(NSURL*)url {
  UIWindowScene* mainScene = [MainSceneCoordinator shared].mainScene;
  
  if (mainScene == nil) {
    return;
  }
  
  [self showWindowOnScene:mainScene];
  
  if (![url startAccessingSecurityScopedResource]) {
    UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:DOLCoreLocalizedString(@"Error") message:@"Failed to start accessing security scoped resource." preferredStyle:UIAlertControllerStyleAlert];
    
    [errorAlert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"OK") style:UIAlertActionStyleDefault
      handler:^(UIAlertAction* action) {
      [self hideWindow];
    }]];
    
    [self presentViewControllerOnWindow:errorAlert];
    
    return;
  }
  
  void (^finish)(void) = ^void() {
    [url stopAccessingSecurityScopedResource];
    
    [self hideWindow];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DOLImportFileFinishedNotification object:self userInfo:nil];
  };
  
  NSString* sourcePath = [url path];
  NSString* destinationPath = [[UserFolderUtil getSoftwareFolder] stringByAppendingPathComponent:[sourcePath lastPathComponent]];
  
  NSFileManager* fileManager = [NSFileManager defaultManager];
  
  if ([fileManager fileExistsAtPath:destinationPath]) {
    UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:DOLCoreLocalizedString(@"Error") message:@"This software has already been imported." preferredStyle:UIAlertControllerStyleAlert];
    
    [errorAlert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"OK") style:UIAlertActionStyleDefault
      handler:^(UIAlertAction* action) {
      finish();
    }]];
    
    [self presentViewControllerOnWindow:errorAlert];
    
    return;
  }
  
  UIAlertController* alert = [UIAlertController alertControllerWithTitle:DOLCoreLocalizedString(@"Import") message:nil preferredStyle:UIAlertControllerStyleAlert];

  [alert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"Copy") style:UIAlertActionStyleDefault
    handler:^(UIAlertAction* action) {
    NSError* error = nil;
    if (![fileManager copyItemAtPath:sourcePath toPath:destinationPath error:&error]) {
      UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:DOLCoreLocalizedString(@"Error") message:[NSString stringWithFormat:@"The copy operation failed.\n\n%@", error.localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
      
      [errorAlert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"OK") style:UIAlertActionStyleDefault
        handler:^(UIAlertAction* action) {
        finish();
      }]];
      
      [self presentViewControllerOnWindow:errorAlert];
    } else {
      finish();
    }
  }]];
  
  [alert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"Move") style:UIAlertActionStyleDefault
    handler:^(UIAlertAction* action) {
    NSError* error = nil;
    if (![fileManager moveItemAtPath:sourcePath toPath:destinationPath error:&error]) {
      UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:DOLCoreLocalizedString(@"Error") message:[NSString stringWithFormat:@"The move operation failed.\n\n%@", error.localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
      
      [errorAlert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"OK") style:UIAlertActionStyleDefault
        handler:^(UIAlertAction* action) {
        finish();
      }]];
      
      [self presentViewControllerOnWindow:errorAlert];
    } else {
      finish();
    }
  }]];
  
  [alert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"Cancel") style:UIAlertActionStyleCancel
    handler:^(UIAlertAction* action) {
    finish();
  }]];
  
  [self presentViewControllerOnWindow:alert];
}

@end
