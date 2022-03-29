// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import Foundation

@objc class UserFolderUtil: NSObject {
  @objc static func getUserFolder() -> String {
#if NONJAILBROKEN
    return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
#else
    return "/private/var/mobile/Documents/DolphiniOS"
#endif
  }
}
