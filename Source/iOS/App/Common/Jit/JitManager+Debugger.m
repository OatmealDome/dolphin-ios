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

@end
