// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import Foundation

@objc protocol JitWaitViewControllerDelegate : AnyObject {
  func didFinishJitScreen(result: Bool, sender: Any)
}
