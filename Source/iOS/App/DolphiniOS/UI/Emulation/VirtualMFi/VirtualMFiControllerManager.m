// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "VirtualMFiControllerManager.h"

#import <GameController/GameController.h>

@interface VirtualMFiControllerManager ()

@end

@implementation VirtualMFiControllerManager {
  GCVirtualController* _controller API_AVAILABLE(ios(15.0));
  bool _isControllerConnected;
}

+ (VirtualMFiControllerManager*)shared {
  static VirtualMFiControllerManager* sharedInstance = nil;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });

  return sharedInstance;
}

- (id)init {
  if (self = [super init]) {
    if (@available(iOS 15.0, *)) {
      GCVirtualControllerConfiguration* configuration = [[GCVirtualControllerConfiguration alloc] init];
      configuration.elements = [NSSet setWithArray:@[
        GCInputButtonA,
        GCInputButtonB,
        GCInputButtonX,
        GCInputButtonY,
        GCInputDirectionPad,
        GCInputLeftThumbstick,
        GCInputRightThumbstick,
        GCInputLeftShoulder,
        GCInputRightShoulder,
        GCInputLeftTrigger,
        GCInputRightTrigger
      ]];
      
      _controller = [GCVirtualController virtualControllerWithConfiguration:configuration];
    }
  }
  
  return self;
}

- (void)connectControllerToView:(UIView*)superview {
  // Yes, this is a gigantic hack. Unfortunately, GCVirtualController likes to attach to the wrong view (UITabBarController),
  // so we need to manually override that by adding it to the requesting controller.
  UIView* controllerView = [_controller valueForKey:@"_controllerView"];
  
  if (_isControllerConnected) {
    [controllerView removeFromSuperview];
    [superview addSubview:controllerView];
  } else {
    [_controller connectWithReplyHandler:^(NSError* error) {
      if (error != nil) {
        NSLog(@"Failed to connect GCVirtualController with error: %@", [error localizedDescription]);
      } else {
        [controllerView removeFromSuperview];
        [superview addSubview:controllerView];
        
        self->_isControllerConnected = true;
      }
    }];
  }
}

- (void)disconnectController {
  if (_controller == nil || !_isControllerConnected) {
    return;
  }
  
  [_controller disconnect];
  
  _isControllerConnected = false;
}

@end
