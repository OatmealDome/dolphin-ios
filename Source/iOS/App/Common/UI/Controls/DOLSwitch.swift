// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import UIKit

#if os(iOS)

typealias DOLSwitch = DOLUIKitSwitch

#else

#error("Unsupported platform")

#endif
