// Copyright 2025 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import Foundation
import UIKit

extension JitManager {
  @objc func acquireJitByStikDebugURLScheme() {
    guard #available(iOS 17.4, *) else {
      return
    }

    guard !StikJITManager.shared.selfEnableJitEnabled else {
      return
    }

    guard let bundleID = Bundle.main.bundleIdentifier else {
      return
    }

    var queryItems = [
      URLQueryItem(name: "bundle-id", value: bundleID),
      URLQueryItem(name: "pid", value: String(getpid())),
    ]

    if self.deviceHasTxm {
      queryItems.append(URLQueryItem(name: "script-name", value: "legacy.js"))
    }

    var components = URLComponents()
    components.scheme = "stikjit"
    components.host = "enable-jit"
    components.queryItems = queryItems

    guard let url = components.url else {
      return
    }

    DispatchQueue.main.async {
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
  }
}
