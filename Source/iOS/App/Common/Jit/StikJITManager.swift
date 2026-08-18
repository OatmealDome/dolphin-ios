// Copyright 2025 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import Foundation
import Darwin

@objc enum JITLaunchMode: Int {
  case waitForDebugger
  case externalStikDebug
  case builtInStikJIT
}

private let kSelfEnableJitDefaultsKey = "stikjit_self_enable_jit"
private let kJITLaunchModeDefaultsKey = "jit_launch_mode"
private let kForceJITScriptDefaultsKey = "stikjit_force_jit_script"
private let kPairingFileDisplayNameDefaultsKey = "stikjit_pairing_file_display_name"
private let kPairingFileName = "pairingFile.plist"
private let kStikJITFolderName = "StikJIT"

@objc class StikJITManager: NSObject {
  @objc static let shared = StikJITManager()

  private let pairingFileURL: URL

  override init() {
    let userFolder = UserFolderUtil.getUserFolder()
    let stikJITFolder = URL(fileURLWithPath: userFolder).appendingPathComponent(kStikJITFolderName)

    try? FileManager.default.createDirectory(at: stikJITFolder, withIntermediateDirectories: true)
    self.pairingFileURL = stikJITFolder.appendingPathComponent(kPairingFileName)

    super.init()
  }

  @objc var jitLaunchMode: JITLaunchMode {
    get {
      if let value = UserDefaults.standard.object(forKey: kJITLaunchModeDefaultsKey) as? NSNumber,
         let mode = JITLaunchMode(rawValue: value.intValue) {
        return mode == .builtInStikJIT && isRunningInLiveContainer ? .waitForDebugger : mode
      }
      let migratedMode: JITLaunchMode = UserDefaults.standard.bool(forKey: kSelfEnableJitDefaultsKey) ? .builtInStikJIT : .waitForDebugger
      return migratedMode == .builtInStikJIT && isRunningInLiveContainer ? .waitForDebugger : migratedMode
    }
    set { UserDefaults.standard.set(newValue.rawValue, forKey: kJITLaunchModeDefaultsKey) }
  }

  @objc var isRunningInLiveContainer: Bool {
    getenv("LC_HOME_PATH") != nil
  }

  @objc var forceJITScriptEnabled: Bool {
    get { UserDefaults.standard.bool(forKey: kForceJITScriptDefaultsKey) }
    set { UserDefaults.standard.set(newValue, forKey: kForceJITScriptDefaultsKey) }
  }

  @objc var hasPairingFile: Bool {
    FileManager.default.fileExists(atPath: pairingFileURL.path)
  }

  @objc var pairingFileDisplayName: String {
    guard hasPairingFile else { return "Not Imported" }
    return UserDefaults.standard.string(forKey: kPairingFileDisplayNameDefaultsKey)
      ?? pairingFileURL.lastPathComponent
  }

  func currentPairingFileURL() -> URL? {
    hasPairingFile ? pairingFileURL : nil
  }

  @objc func importPairingFile(_ sourceURL: URL) throws {
    if FileManager.default.fileExists(atPath: pairingFileURL.path) {
      try FileManager.default.removeItem(at: pairingFileURL)
    }

    try FileManager.default.copyItem(at: sourceURL, to: pairingFileURL)
    UserDefaults.standard.set(sourceURL.lastPathComponent, forKey: kPairingFileDisplayNameDefaultsKey)
  }
}
