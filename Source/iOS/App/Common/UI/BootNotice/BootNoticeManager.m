// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "BootNoticeManager.h"

#import "BootNoticeNavigationViewController.h"
#import "MainSceneCoordinator.h"

@implementation BootNoticeManager {
  NSMutableArray<UIViewController*>* _queuedControllers;
  BootNoticeNavigationViewController* _navigationController;
}

+ (BootNoticeManager*)shared {
  static BootNoticeManager* sharedInstance = nil;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });

  return sharedInstance;
}

- (instancetype)init {
  if (self = [super init]) {
    _queuedControllers = [[NSMutableArray alloc] init];
    
    _navigationController = [[BootNoticeNavigationViewController alloc] init];
    _navigationController.navigationBarHidden = true;
    _navigationController.modalInPresentation = true;
    _navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
  }
  
  return self;
}

- (BOOL)isBeingPresented {
  UIWindowScene* scene = [MainSceneCoordinator shared].mainScene;
  
  if (scene == nil) {
    return false;
  }
  
  return scene.windows[0].rootViewController.presentedViewController == _navigationController;
}

- (void)enqueueViewController:(UIViewController*)viewController {
  if (![self isBeingPresented]) {
    [_queuedControllers addObject:viewController];
  } else {
    [_navigationController presentViewController:viewController animated:true completion:nil];
  }
}

- (void)presentToSceneIfNecessary {
  if (_queuedControllers.count == 0) {
    return;
  }
  
  UIWindowScene* scene = [MainSceneCoordinator shared].mainScene;
  
  if (scene == nil) {
    return;
  }
  
  UIViewController* rootViewController = scene.windows[0].rootViewController;
  
  if (rootViewController.presentedViewController == _navigationController) {
    return;
  }
  
  for (UIViewController* controller in _queuedControllers) {
    [_navigationController pushViewController:controller animated:false];
  }
  
  [_queuedControllers removeAllObjects];
  
  [rootViewController presentViewController:_navigationController animated:true completion:nil];
}

@end
