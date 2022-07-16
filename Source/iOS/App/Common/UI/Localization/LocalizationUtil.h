// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

// Generic preprocessor macros that can be used with any table.

#define DOLLocalizedString(x, y) NSLocalizedStringFromTable(x, y, nil)
#define DOLLocalizedStringWithArgs(x, y, ...) [LocalizationUtil setFormatSpecifiersOnQString:DOLLocalizedString(x, y), __VA_ARGS__, nil]

// Macros that use the Core table.

#define DOLCoreLocalizedString(x) DOLLocalizedString(x, @"Core")
#define DOLCoreLocalizedStringWithArgs(x, ...) [LocalizationUtil setFormatSpecifiersOnQString:DOLCoreLocalizedString(x), __VA_ARGS__, nil]

NS_ASSUME_NONNULL_BEGIN

@interface LocalizationUtil : NSObject

+ (NSString*)setFormatSpecifiersOnQString:(NSString*)str, ...;

@end

NS_ASSUME_NONNULL_END
