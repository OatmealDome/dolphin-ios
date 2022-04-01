// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

// Objective-C++ does not support modules, but the Swift header uses them.
// This header imports the necessary framework headers in place of modules
// so that Swift code can be used within Objective-C++.

#import <UIKit/UIKit.h>

// Import the Swift header now.

#import "DolphiniOS-Swift.h"
