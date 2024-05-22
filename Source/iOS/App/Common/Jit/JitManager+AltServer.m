// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "JitManager+AltServer.h"

#import <objc/runtime.h>

@import AltKit;

@interface JitManager (AltServerPrivate)
@property (nonatomic) BOOL isAltServerAutoConnecting;
@end

@implementation JitManager (AltServerPrivate)

// Hack: Private property

- (BOOL)isAltServerAutoConnecting {
  return [objc_getAssociatedObject(self, @selector(isAltServerAutoConnecting)) boolValue];
}

- (void)setIsAltServerAutoConnecting:(BOOL)result {
  objc_setAssociatedObject(self, @selector(isAltServerAutoConnecting), [NSNumber numberWithBool:result], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation JitManager (AltServer)

- (bool)checkAppInstalledByAltServer {
  NSString* deviceId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"ALTDeviceID"];

  if (!deviceId) {
    return false;
  }

  // If ALTDeviceID isn't our dummy value, then we can use AltServer to enable JIT.
  return ![deviceId isEqualToString:@"NotSet"];
}

- (void)beginAltServerAutoDiscover {
  [[ALTServerManager sharedManager] startDiscovering];
}

- (void)stopAltServerAutoDiscover {
  [[ALTServerManager sharedManager] stopDiscovering];
}

- (void)acquireJitByAltServer {
  if (self.isAltServerAutoConnecting || ![self checkAppInstalledByAltServer]) {
    return;
  }
  
  self.isAltServerAutoConnecting = YES;
  
  // TODO: Localization
  [[ALTServerManager sharedManager] autoconnectWithCompletionHandler:^(ALTServerConnection *connection, NSError *error) {
    if (error != nil) {
      self.acquisitionError = [NSString stringWithFormat:@"Failed to connect to AltServer: %@", [error localizedDescription]];
      self.isAltServerAutoConnecting = NO;
    } else {
      [connection enableUnsignedCodeExecutionWithCompletionHandler:^(bool success, NSError* error) {
        if (!success) {
          self.acquisitionError = [NSString stringWithFormat:@"AltServer failed to enable JIT: %@", [error localizedDescription]];
        }

        [connection disconnect];

        self.isAltServerAutoConnecting = NO;
      }];
    }
  }];
}

@end
