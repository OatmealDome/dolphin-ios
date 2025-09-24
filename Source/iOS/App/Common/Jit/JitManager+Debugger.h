// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "JitManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface JitManager (Debugger)

- (bool)checkIfProcessIsDebugged;
- (bool)checkIfDeviceUsesTXM;

@end

NS_ASSUME_NONNULL_END
