// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import UIKit

@UIApplicationMain
class AppDelegate : UIResponder, UIApplicationDelegate {
  var window: UIWindow?
  
  let services: [UIApplicationDelegate] = [
    DefaultsInitService(),
    DolphinCoreService()
  ]
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    var returnedResult: Bool = true
        
    for service in services {
      let result = service.application?(application, didFinishLaunchingWithOptions: launchOptions) ?? true
      
      if (!result) {
        returnedResult = false
      }
    }
    
    return returnedResult;
  }
  
  func applicationWillTerminate(_ application: UIApplication) {
    for service in services {
      service.applicationWillTerminate?(application)
    }
  }
  
  func applicationDidBecomeActive(_ application: UIApplication) {
    for service in services {
      service.applicationDidBecomeActive?(application)
    }
  }
  
  func applicationWillResignActive(_ application: UIApplication) {
    for service in services {
      service.applicationWillResignActive?(application)
    }
  }
  
  func applicationDidEnterBackground(_ application: UIApplication) {
    for service in services {
      service.applicationDidEnterBackground?(application)
    }
  }
  
  func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
    for service in services {
      service.applicationDidReceiveMemoryWarning?(application)
    }
  }
  
  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    var returnedResult: Bool = true
    
    for service in services {
      let result = service.application?(app, open: url, options: options) ?? true
      
      if (!result) {
        returnedResult = false
      }
    }
    
    return returnedResult;
  }
}
