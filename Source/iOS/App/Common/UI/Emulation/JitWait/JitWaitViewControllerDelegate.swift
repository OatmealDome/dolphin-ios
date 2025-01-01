// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import Foundation

@objc enum JitWaitViewControllerResult: Int {
  case jitAcquired
  case noJitRequested
  case cancel
}

@objc protocol JitWaitViewControllerDelegate : AnyObject {
  func didFinishJitScreen(result: JitWaitViewControllerResult, sender: Any)
}
