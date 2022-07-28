// Copyright 2019 Dolphin Emulator Project
// Licensed under GPLv2+
// Refer to the license.txt file included.

#pragma once

#include <Foundation/Foundation.h>

@interface MFiControllerScanner : NSObject

- (void)beginScan;
- (void)endScan;

@end
