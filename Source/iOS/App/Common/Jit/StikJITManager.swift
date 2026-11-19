// Copyright 2025 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import CryptoKit
import Foundation

@objc enum JITLaunchMode: Int {
  case waitForDebugger
  case externalStikDebug
  case builtInStikJIT
}

private let kSelfEnableJitDefaultsKey = "stikjit_self_enable_jit"
private let kJITLaunchModeDefaultsKey = "jit_launch_mode"
private let kForceJITScriptDefaultsKey = "stikjit_force_jit_script"
private let kValidatedPairingFileDigestKey = "stikjit_validated_pairing_file_digest"
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
        return mode
      }
      let migratedMode: JITLaunchMode = UserDefaults.standard.bool(forKey: kSelfEnableJitDefaultsKey) ? .builtInStikJIT : .waitForDebugger
      return migratedMode
    }
    set { UserDefaults.standard.set(newValue.rawValue, forKey: kJITLaunchModeDefaultsKey) }
  }

  @objc var forceJITScriptEnabled: Bool {
    get { UserDefaults.standard.bool(forKey: kForceJITScriptDefaultsKey) }
    set { UserDefaults.standard.set(newValue, forKey: kForceJITScriptDefaultsKey) }
  }

  @objc var hasPairingFile: Bool {
    FileManager.default.fileExists(atPath: pairingFileURL.path)
  }

  @objc var pairingFileStatus: String {
    guard hasPairingFile else {
      UserDefaults.standard.removeObject(forKey: kValidatedPairingFileDigestKey)
      return "Missing"
    }

    guard let digest = UserDefaults.standard.data(forKey: kValidatedPairingFileDigestKey),
          let pairingData = try? Data(contentsOf: pairingFileURL),
          Data(SHA256.hash(data: pairingData)) == digest else {
      return "Imported"
    }
    return "Validated"
  }

  func markPairingFileValidated(_ pairingData: Data) {
    guard let currentData = try? Data(contentsOf: pairingFileURL), currentData == pairingData else {
      return
    }
    UserDefaults.standard.set(Data(SHA256.hash(data: pairingData)), forKey: kValidatedPairingFileDigestKey)
  }

  func currentPairingFileURL() -> URL? {
    hasPairingFile ? pairingFileURL : nil
  }

  @objc func importPairingFile(_ sourceURL: URL) throws {
    if FileManager.default.fileExists(atPath: pairingFileURL.path) {
      try FileManager.default.removeItem(at: pairingFileURL)
    }

    UserDefaults.standard.removeObject(forKey: kValidatedPairingFileDigestKey)
    try FileManager.default.copyItem(at: sourceURL, to: pairingFileURL)
  }
}
