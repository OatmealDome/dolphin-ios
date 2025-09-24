// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "JitManager+Debugger.h"

#define CS_OPS_STATUS 0
#define CS_DEBUGGED 0x10000000

extern int csops(pid_t pid, unsigned int ops, void* useraddr, size_t usersize);

@implementation JitManager (Debugger)

- (bool)checkIfProcessIsDebugged {
  int flags;
  if (csops(getpid(), CS_OPS_STATUS, &flags, sizeof(flags) != 0)) {
    return false;
  }

  return flags & CS_DEBUGGED;
}

// The following is taken from StikDebug.
// https://github.com/StephenDev0/StikDebug/blob/d077e232a9ff548d69a21e0e55466e8c7e9edb11/StikJIT/Views/HomeView.swift#L895-L908

- (nullable NSString*)filePathAtPath:(NSString*)path withLength:(NSUInteger)length {
    NSError *error = nil;
    NSArray<NSString *> *items = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    if (!items) { return nil; }

    for (NSString *entry in items) {
        if (entry.length == length) {
            return [path stringByAppendingPathComponent:entry];
        }
    }
    return nil;
}

- (bool)checkIfDeviceUsesTXM {
    // Primary: /System/Volumes/Preboot/<36>/boot/<96>/usr/.../Ap,TrustedExecutionMonitor.img4
    NSString* bootUUID = [self filePathAtPath:@"/System/Volumes/Preboot" withLength:36];
    if (bootUUID) {
        NSString* bootDir = [bootUUID stringByAppendingPathComponent:@"boot"];
        NSString* ninetySixCharPath = [self filePathAtPath:bootDir withLength:96];
        if (ninetySixCharPath) {
            NSString* img = [ninetySixCharPath stringByAppendingPathComponent:
                             @"usr/standalone/firmware/FUD/Ap,TrustedExecutionMonitor.img4"];
            return access(img.fileSystemRepresentation, F_OK) == 0;
        }
    }

    // Fallback: /private/preboot/<96>/usr/.../Ap,TrustedExecutionMonitor.img4
    NSString* fallback = [self filePathAtPath:@"/private/preboot" withLength:96];
    if (fallback) {
        NSString* img = [fallback stringByAppendingPathComponent:
                         @"usr/standalone/firmware/FUD/Ap,TrustedExecutionMonitor.img4"];
        return access(img.fileSystemRepresentation, F_OK) == 0;
    }

    return false;
}


@end
