// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import UIKit

class ExternalDisplaySceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?
  
  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    EmulationCoordinator.shared().isExternalDisplayConnected = true
  }
  
  func sceneDidDisconnect(_ scene: UIScene) {
    EmulationCoordinator.shared().isExternalDisplayConnected = false
  }
  
  func sceneDidBecomeActive(_ scene: UIScene) {
    //
  }
  
  func sceneWillResignActive(_ scene: UIScene) {
    //
  }
  
  func sceneWillEnterForeground(_ scene: UIScene) {
    //
  }
  
  func sceneDidEnterBackground(_ scene: UIScene) {
    //
  }
}
