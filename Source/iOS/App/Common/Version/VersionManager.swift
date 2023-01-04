// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import Foundation

@objc class VersionManager: NSObject {
  
  private static let sharedInstance = VersionManager()
  
  class func shared() -> VersionManager {
    return sharedInstance
  }
  
  private(set) var version: String // "4.0.0"
  private(set) var build: Int // 1
  
  private(set) var userFacingVersion: String // "4.0.0 (1)"
  
  private(set) var coreVersion: String // "5.0-12345"
  
  private (set) var buildSource: DOLBuildSource
  
  private override init() {
    let info = Bundle.main.infoDictionary!
    
    version = info["CFBundleShortVersionString"] as! String
    build = Int(info["CFBundleVersion"] as! String)!
    
    userFacingVersion = String(format: "%@ (%d)", version, build)
    
    coreVersion = info["DOLCoreVersion"] as! String
    
    switch (info["DOLBuildSource"] as! String) {
    case "development":
      buildSource = .development
    case "unofficial":
      buildSource = .unofficial
    case "official":
      buildSource = .official
    default:
      buildSource = .development
    }
  }
}
