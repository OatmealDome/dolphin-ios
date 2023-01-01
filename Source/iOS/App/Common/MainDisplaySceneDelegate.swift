// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import UIKit

class MainDisplaySceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?
  
  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    MainSceneCoordinator.shared().mainScene = scene as? UIWindowScene
  }
  
  func sceneDidDisconnect(_ scene: UIScene) {
    MainSceneCoordinator.shared().mainScene = nil
  }
  
  func sceneDidBecomeActive(_ scene: UIScene) {
    ServiceManager.shared.applicationDidBecomeActive()
    
    BootNoticeManager.shared().presentToSceneIfNecessary()
  }
  
  func sceneWillResignActive(_ scene: UIScene) {
    ServiceManager.shared.applicationWillResignActive()
  }
  
  func sceneWillEnterForeground(_ scene: UIScene) {
    //
  }
  
  func sceneDidEnterBackground(_ scene: UIScene) {
    ServiceManager.shared.applicationDidEnterBackground()
  }
}
