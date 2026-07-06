// Copyright 2025 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import Foundation

func appendingStikJITTroubleshootingHint(_ message: String) -> String {
  guard message.contains("Connection refused") else { return message }
  return "\(message) Reboot your device, then try again."
}

@objc class DDIManager: NSObject {
  @objc static let shared = DDIManager()

  private var ddiDirectory: URL {
    let libraryFolder = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
    return URL(fileURLWithPath: libraryFolder).appendingPathComponent("StikJIT")
  }

  private var ddiPaths: DDIPaths {
    DDIPaths.default(in: ddiDirectory)
  }

  @objc func checkStatus(completion: @escaping (String) -> Void) {
    guard #available(iOS 17.4, *) else {
      completion("Unavailable")
      return
    }

    completion(ddiPaths.allFilesExist ? "Present" : "Not Present")
  }

  @objc func deleteCachedDDI() {
    try? FileManager.default.removeItem(at: ddiDirectory.appendingPathComponent("DDI"))
  }

  @objc func checkIsMounted(completion: @escaping (Bool, String?) -> Void) {
    guard #available(iOS 17.4, *) else {
      completion(false, "Requires iOS 17.4 or later.")
      return
    }

    guard let pairingFileURL = StikJITManager.shared.currentPairingFileURL() else {
      completion(false, "No pairing file imported.")
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let mounted = try StikJIT.isDDIMounted(pairingFile: pairingFileURL)
        DispatchQueue.main.async { completion(mounted, nil) }
      } catch {
        DispatchQueue.main.async { completion(false, appendingStikJITTroubleshootingHint(error.localizedDescription)) }
      }
    }
  }

  @objc func mountDDI(progress: @escaping (Double, String) -> Void, completion: @escaping (Bool, String?) -> Void) {
    guard #available(iOS 17.4, *) else {
      completion(false, "Requires iOS 17.4 or later.")
      return
    }

    guard let pairingFileURL = StikJITManager.shared.currentPairingFileURL() else {
      completion(false, "No pairing file imported.")
      return
    }

    Task {
      do {
        let paths = ddiPaths
        try await StikJIT.downloadDDIIfNeeded(to: paths) { fraction, status in
          DispatchQueue.main.async { progress(fraction, status) }
        }
        DispatchQueue.main.async { progress(1, "Mounting Developer Disk Image...") }
        try StikJIT.mountDDI(pairingFile: pairingFileURL, paths: paths) { fraction in
          DispatchQueue.main.async { progress(fraction, "Mounting Developer Disk Image...") }
        }
        DispatchQueue.main.async { completion(true, nil) }
      } catch {
        DispatchQueue.main.async { completion(false, appendingStikJITTroubleshootingHint(error.localizedDescription)) }
      }
    }
  }
}
