// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "JitManager.h"

extern const char* _Nonnull DOLJitPTraceChildProcessArgument;

NS_ASSUME_NONNULL_BEGIN

@interface JitManager (PTrace)

- (void)runPTraceStartupTasks;
- (void)acquireJitByPTrace;

@end

NS_ASSUME_NONNULL_END
