// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import Foundation

@objc public class DOLAppVersion: NSObject, Comparable {
  private let major: Int;
  private let minor: Int;
  private let patch: Int;
  private let betaNumber: Int?;
  private let build: Int;
  
  @objc let source: DOLBuildSource
  @objc let userFacing: String
  
  public init(shortVersion: String, version: String, buildSource: DOLBuildSource) {
    let splitShort = shortVersion.split(separator: ".")
    
    major = Int(splitShort[0])!
    minor = Int(splitShort[1])!
    
    let patchStr = splitShort[2]
    
    if (patchStr.contains("b")) {
      let splitPatchStr = patchStr.split(separator: "b")
      
      patch = Int(splitPatchStr[0])!
      betaNumber = Int(splitPatchStr[1])!
    } else {
      patch = Int(patchStr)!
      betaNumber = nil
    }
    
    build = Int(version)!
    
    source = buildSource
    
    let overrideBuild: String
    
    switch (source) {
    case .development:
      overrideBuild = "D"
    case .unofficial:
      overrideBuild = "U"
    case .official:
      overrideBuild = String(build)
    default:
      overrideBuild = "?"
    }
    
    let betaComponent: String
    
    if let betaNumber = betaNumber {
      betaComponent = String(format: "b%d", betaNumber)
    } else {
      betaComponent = ""
    }
    
    userFacing = String(format: "%d.%d.%d%@ (%@)", major, minor, patch, betaComponent, overrideBuild)
  }
  
  public convenience init(jsonVersion: String) {
    let splitVersion = jsonVersion.split(separator: " ")
    
    let sanitizedBuild = splitVersion[1]
      .replacingOccurrences(of: "(", with: "")
      .replacingOccurrences(of: ")", with: "")
    
    self.init(shortVersion: String(splitVersion[0]), version: sanitizedBuild, buildSource: .official)
  }
  
  public convenience override init() {
    let info = Bundle.main.infoDictionary!
    
    let shortVersion = info["CFBundleShortVersionString"] as! String
    let version = info["CFBundleVersion"] as! String
    
    let buildSource: DOLBuildSource
    
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
    
    self.init(shortVersion: shortVersion, version: version, buildSource: buildSource)
  }
  
  public static func < (lhs: DOLAppVersion, rhs: DOLAppVersion) -> Bool {
    let lhsBetaNumber = lhs.betaNumber ?? Int.max
    let rhsBetaNumber = rhs.betaNumber ?? Int.max
    
    if (lhs.major > rhs.major) {
      return false
    }
    
    if (lhs.minor > rhs.minor) {
      return false
    }
    
    if (lhs.patch > rhs.patch) {
      return false
    }
    
    if (lhsBetaNumber > rhsBetaNumber) {
      return false
    }
    
    if (lhs.build > rhs.build) {
      return false
    }
    
    if (lhs == rhs) {
      return false
    }
    
    return true
  }
  
  override public func isEqual(_ object: Any?) -> Bool {
    let lhs = self
    
    guard let rhs = object as? DOLAppVersion else {
      return false
    }
    
    return lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch && lhs.betaNumber == rhs.betaNumber && lhs.build == rhs.build
  }
}
