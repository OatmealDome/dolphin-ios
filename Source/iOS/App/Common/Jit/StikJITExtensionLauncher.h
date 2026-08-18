// Copyright 2025 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol StikJITRunnerXPCProtocol
- (void)detectTXM;
- (void)prepareDeviceWithPairingData:(NSData*)pairingData;
- (void)resetCachedDDI;
- (void)enableJITForParentPID:(int32_t)pid
                  pairingData:(NSData*)pairingData
                  forceScript:(BOOL)forceScript;
@end

@protocol StikJITHostXPCProtocol
- (void)txmDetectionFinished:(nullable NSNumber*)txmPresent;
- (void)preparationProgress:(NSString*)stage fraction:(double)fraction detail:(nullable NSString*)detail;
- (void)preparationFinished:(NSString*)readiness
                     reason:(nullable NSString*)reason
                 txmPresent:(nullable NSNumber*)txmPresent;
- (void)ddiResetFinished:(BOOL)ok error:(nullable NSString*)error;
- (void)jitLog:(NSString*)line;
- (void)jitFinished:(BOOL)ok error:(nullable NSString*)error;
@end

@interface StikJITExtensionLauncher : NSObject

- (instancetype)initWithHost:(id<StikJITHostXPCProtocol>)host;

- (void)launchWithCompletion:(void (^)(int32_t pid,
                                       id<StikJITRunnerXPCProtocol> _Nullable runner,
                                       NSError* _Nullable error))completion;

- (void)invalidate;

@end

NS_ASSUME_NONNULL_END
