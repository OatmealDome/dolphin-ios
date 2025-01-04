// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import Foundation
import UIKit

class ServiceManager {
  static let shared = ServiceManager()
  
  var application: UIApplication? = nil
  
  let services: [UIApplicationDelegate] = [
    DefaultsInitService(),
    DolphinCoreService(),
    FirstRunInitializationService(),
    LegacyInputConfigMigrationService(),
    GameFileCacheService(),
    JitAcquisitionService(),
    FirebaseService(),
    AudioSessionCategoryService(),
    UpdateCheckService()
  ]
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    self.application = application
    
    var returnedResult: Bool = true
        
    for service in services {
      let result = service.application?(application, didFinishLaunchingWithOptions: launchOptions) ?? true
      
      if (!result) {
        returnedResult = false
      }
    }
    
    return returnedResult;
  }
  
  func applicationWillTerminate() {
    for service in services {
      service.applicationWillTerminate?(self.application!)
    }
  }
  
  func applicationDidBecomeActive() {
    for service in services {
      service.applicationDidBecomeActive?(self.application!)
    }
  }
  
  func applicationWillResignActive() {
    for service in services {
      service.applicationWillResignActive?(self.application!)
    }
  }
  
  func applicationDidEnterBackground() {
    for service in services {
      service.applicationDidEnterBackground?(self.application!)
    }
  }
  
  func applicationDidReceiveMemoryWarning() {
    for service in services {
      service.applicationDidReceiveMemoryWarning?(self.application!)
    }
  }
  
  func open(url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    var returnedResult: Bool = true
    
    for service in services {
      let result = service.application?(self.application!, open: url, options: options) ?? true
      
      if (!result) {
        returnedResult = false
      }
    }
    
    return returnedResult;
  }
}
