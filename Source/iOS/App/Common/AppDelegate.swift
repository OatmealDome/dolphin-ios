// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import UIKit

@UIApplicationMain
class AppDelegate : UIResponder, UIApplicationDelegate {
  var window: UIWindow?
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    ServiceManager.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  func applicationWillTerminate(_ application: UIApplication) {
    ServiceManager.shared.applicationWillTerminate()
  }
  
  func applicationDidBecomeActive(_ application: UIApplication) {
    ServiceManager.shared.applicationDidBecomeActive()
  }
  
  func applicationWillResignActive(_ application: UIApplication) {
    ServiceManager.shared.applicationWillResignActive()
  }
  
  func applicationDidEnterBackground(_ application: UIApplication) {
    ServiceManager.shared.applicationDidEnterBackground()
  }
  
  func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
    ServiceManager.shared.applicationDidReceiveMemoryWarning()
  }
  
  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    ServiceManager.shared.open(url: url, options: options)
  }
}
