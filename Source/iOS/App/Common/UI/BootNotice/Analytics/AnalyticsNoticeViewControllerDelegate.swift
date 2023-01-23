// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import Foundation

@objc protocol AnalyticsNoticeViewControllerDelegate : AnyObject {
  func didFinishAnalyticsNotice(result: Bool, sender: Any)
}
