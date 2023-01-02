// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

#import "JitManager+PTrace.h"
#import "Swift.h"

int main(int argc, char* argv[]) {
  NSString* appDelegateClassName;
  @autoreleasepool {
    // Setup code that might create autoreleased objects goes here.
    appDelegateClassName = NSStringFromClass([AppDelegate class]);
    
    // If this is a child process spawned by us, run ptrace now.
    if (argc >= 2 && strncmp(argv[1], DOLJitPTraceChildProcessArgument, strlen(DOLJitPTraceChildProcessArgument)) == 0) {
      [[JitManager shared] runPTraceStartupTasks];
      
      return 0;
    }
  }
  
  return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
