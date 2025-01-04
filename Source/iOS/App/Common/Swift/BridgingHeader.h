// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "AudioSessionManager.h"
#import "BootNoticeManager.h"
#import "DolphinCoreService.h"
#import "EmulationCoordinator.h"
#import "FirebaseService.h"
#import "FirstRunInitializationService.h"
#import "GameFileCacheManager.h"
#import "JitManager.h"
#import "JitManager+AltServer.h"
#import "JitManager+JitStreamer.h"
#import "JitManager+PTrace.h"
#import "LegacyInputConfigMigrationService.h"
#import "MainSceneCoordinator.h"
#import "UpdateNoticeViewController.h"
#import "UpdateRequiredNoticeViewController.h"

#if TARGET_OS_IOS
#import "DOLUIKitSwitch.h"
#import "TCManagerInterface.h"
#endif
