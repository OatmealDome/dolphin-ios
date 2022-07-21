// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

#import "Core/HW/WiimoteEmu/WiimoteEmu.h"

NS_ASSUME_NONNULL_BEGIN

@interface MappingUtil : NSObject

+ (NSString*)getLocalizedStringForWiimoteExtension:(WiimoteEmu::ExtensionNumber)extension;

@end

NS_ASSUME_NONNULL_END
