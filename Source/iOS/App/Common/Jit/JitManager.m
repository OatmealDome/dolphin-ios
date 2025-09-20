// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "JitManager.h"

#import "JitManager+Debugger.h"

typedef NS_ENUM(NSInteger, DOLJitType) {
  DOLJitTypeDebugger,
  DOLJitTypeUnrestricted
};

@interface JitManager ()

@property (readwrite, assign) bool acquiredJit;

@end

@implementation JitManager {
  DOLJitType _jitType;
}

+ (JitManager*)shared {
  static JitManager* sharedInstance = nil;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });

  return sharedInstance;
}

- (id)init {
  if (self = [super init]) {
#if TARGET_OS_SIMULATOR
    _jitType = DOLJitTypeUnrestricted;
#else
    _jitType = DOLJitTypeDebugger;
#endif
    
    self.acquiredJit = false;
  }
  
  return self;
}

- (void)recheckIfJitIsAcquired {
  if (_jitType == DOLJitTypeDebugger) {
    if (@available(iOS 26, *)) {
      NSDictionary* environment = [[NSProcessInfo processInfo] environment];
      
      if ([environment objectForKey:@"XCODE"] != nil) {
        self.acquisitionError = @"JIT cannot be enabled while running within Xcode on iOS 26.";
        return;
      }
    }
    
    self.acquiredJit = [self checkIfProcessIsDebugged];
  } else if (_jitType == DOLJitTypeUnrestricted) {
    self.acquiredJit = true;
  }
}

@end
