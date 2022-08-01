// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import Foundation

@objc protocol NKitWarningViewControllerDelegate : AnyObject {
  func didFinishNKitWarningScreen(result: Bool, sender: Any)
}
