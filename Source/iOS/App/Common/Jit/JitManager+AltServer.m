// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "JitManager+AltServer.h"

#import <objc/runtime.h>

@import AltKit;

@interface JitManager (AltServer)

@property (nonatomic) bool isAltServerAutoConnecting;

@end

@implementation JitManager (AltServer)

- (bool)checkAppInstalledByAltServer {
  NSString* deviceId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"ALTDeviceID"];
  
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
  
  self.isAltServerAutoConnecting = true;
  
  // TODO: Localization
  [[ALTServerManager sharedManager] autoconnectWithCompletionHandler:^(ALTServerConnection *connection, NSError *error) {
    if (error != nil) {
      self.acquisitionError = [NSString stringWithFormat:@"Failed to connect to AltServer: %@", [error localizedDescription]];
    } else {
      [connection enableUnsignedCodeExecutionWithCompletionHandler:^(bool success, NSError* error) {
        if (!success) {
          self.acquisitionError = [NSString stringWithFormat:@"AltServer failed to enable JIT: %@", [error localizedDescription]];
        }
        
        [connection disconnect];
      }];
    }
  }];
}

// Hack: Private property

- (bool)isAltServerAutoConnecting {
  return [objc_getAssociatedObject(self, @selector(isAltServerAutoConnecting)) boolValue];
}

- (void)setIsAltServerAutoConnecting:(bool)result {
  objc_setAssociatedObject(self, @selector(isAltServerAutoConnecting), [NSNumber numberWithBool:result], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
