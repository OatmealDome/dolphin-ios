// Copyright 2025 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import Foundation

private let kSelfEnableJitDefaultsKey = "stikjit_self_enable_jit"
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

  @objc var selfEnableJitEnabled: Bool {
    get { UserDefaults.standard.bool(forKey: kSelfEnableJitDefaultsKey) }
    set { UserDefaults.standard.set(newValue, forKey: kSelfEnableJitDefaultsKey) }
  }

  @objc var hasPairingFile: Bool {
    FileManager.default.fileExists(atPath: pairingFileURL.path)
  }

  @objc var pairingFileDisplayName: String {
    hasPairingFile ? pairingFileURL.lastPathComponent : "Not Imported"
  }

  func currentPairingFileURL() -> URL? {
    hasPairingFile ? pairingFileURL : nil
  }

  @objc func importPairingFile(_ sourceURL: URL) throws {
    if FileManager.default.fileExists(atPath: pairingFileURL.path) {
      try FileManager.default.removeItem(at: pairingFileURL)
    }

    try FileManager.default.copyItem(at: sourceURL, to: pairingFileURL)
  }
}
