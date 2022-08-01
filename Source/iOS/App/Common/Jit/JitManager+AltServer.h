// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "JitManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface JitManager (AltServer)

- (bool)checkAppInstalledByAltServer;
- (void)beginAltServerAutoDiscover;
- (void)stopAltServerAutoDiscover;
- (void)acquireJitByAltServer;

@end

NS_ASSUME_NONNULL_END
