// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import UIKit

class JitAcquisitionService : UIResponder, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    let manager = JitManager.shared()
    
    manager.recheckIfJitIsAcquired()
    
    if (!manager.acquiredJit) {
      manager.acquireJitByPTrace()
      
#if NONJAILBROKEN
      manager.acquireJitByAltServer()
#endif
    }
    
    return true
  }
}
