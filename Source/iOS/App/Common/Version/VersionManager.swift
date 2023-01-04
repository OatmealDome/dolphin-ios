// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import Foundation

@objcMembers class VersionManager: NSObject {
  
  private static let sharedInstance = VersionManager()
  
  class func shared() -> VersionManager {
    return sharedInstance
  }
  
  private(set) var version: String // "4.0.0"
  private(set) var build: Int // 1
  
  private(set) var userFacingVersion: String // "4.0.0 (1)"
  
  private(set) var coreVersion: String // "5.0-12345"
  
  private(set) var buildSource: DOLBuildSource
  
  private override init() {
    let info = Bundle.main.infoDictionary!
    
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
    
    version = info["CFBundleShortVersionString"] as! String
    build = Int(info["CFBundleVersion"] as! String)!
    
    let buildForUserFacing: String
    
    switch (buildSource) {
    case .development:
      buildForUserFacing = "D"
    case .unofficial:
      buildForUserFacing = "U"
    case .official:
      buildForUserFacing = String(build)
    default:
      buildForUserFacing = "?"
    }
    
    userFacingVersion = String(format: "%@ (%@)", version, buildForUserFacing)
    
    coreVersion = info["DOLCoreVersion"] as! String
  }
}
