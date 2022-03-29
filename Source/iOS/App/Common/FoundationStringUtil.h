// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#ifdef __OBJC__

#import <Foundation/Foundation.h>

#define FoundationToCString(x) [x UTF8String]

#define CToFoundationString(x) [NSString stringWithUTF8String:x]

#ifdef __cplusplus

#import <string>

#define FoundationToCppString(x) std::string(FoundationToCString(x))

#define CppToFoundationString(x) CToFoundationString(x.c_str())

#endif // __cplusplus

#endif // __OBJC__
