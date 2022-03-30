// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import Foundation

extension String {
  func stringByAppendingPathComponent(_ path: String) -> String {
    return (self as NSString).appendingPathComponent(path)
  }
}
