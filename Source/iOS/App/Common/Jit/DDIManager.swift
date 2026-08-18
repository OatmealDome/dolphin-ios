// Copyright 2025 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import Foundation

func appendingStikJITTroubleshootingHint(_ message: String) -> String {
  if message.contains("NSExtension creation failed") {
    return "\(message) StikJIT currently will not work inside LiveContainer."
  }
  if message.contains("Timed out connecting to 10.7.0.1:49152") {
    return "\(message) Make sure LocalDevVPN is connected and either a Wi-Fi network is connected or Airplane Mode is enabled."
  }
  if message.contains("Connection refused") {
    return "\(message) Reboot your device, then try again."
  }
  return message
}

private final class DDIXPCHostBridge: NSObject, StikJITHostXPCProtocol {
  var onTXMDetectionFinished: ((NSNumber?) -> Void)?
  var onPreparationProgress: ((String, Double, String?) -> Void)?
  var onPreparationFinished: ((String, String?, NSNumber?) -> Void)?
  var onResetFinished: ((Bool, String?) -> Void)?

  func txmDetectionFinished(_ txmPresent: NSNumber?) {
    onTXMDetectionFinished?(txmPresent)
  }

  func preparationProgress(_ stage: String, fraction: Double, detail: String?) {
    onPreparationProgress?(stage, fraction, detail)
  }

  func preparationFinished(_ readiness: String, reason: String?, txmPresent: NSNumber?) {
    onPreparationFinished?(readiness, reason, txmPresent)
  }

  func ddiResetFinished(_ ok: Bool, error: String?) {
    onResetFinished?(ok, error)
  }

  func jitLog(_ line: String) {}
  func jitFinished(_ ok: Bool, error: String?) {}
}

@objc class DDIManager: NSObject {
  @objc static let shared = DDIManager()

  @objc private(set) var preparationStatus = "Not Checked"
  @objc private(set) var preparationFailureReason = ""
  @objc private(set) var txmStatus = "Unknown"

  private var activeLauncher: StikJITExtensionLauncher?
  private var activeHost: DDIXPCHostBridge?

  @objc func invalidateReadiness() {
    updateReadiness(status: "Not Checked", reason: nil)
  }

  @objc func detectTXM(completion: @escaping () -> Void) {
    guard #available(iOS 17.4, *) else {
      updateTXMStatus(nil)
      completion()
      return
    }

    startOperation { runner, finish in
      self.activeHost?.onTXMDetectionFinished = { txmPresent in
        DispatchQueue.main.async {
          self.updateTXMStatus(txmPresent)
          finish()
          completion()
        }
      }
      runner.detectTXM()
    } failure: { _ in
      self.updateTXMStatus(nil)
      completion()
    }
  }

  @objc func prepareDevice(
    progress: @escaping (Double, String) -> Void,
    completion: @escaping (Bool, String?) -> Void
  ) {
    guard #available(iOS 17.4, *) else {
      updateReadiness(status: "Not Ready", reason: "Requires iOS 17.4 or later.")
      completion(false, preparationFailureReason)
      return
    }

    guard let pairingFileURL = StikJITManager.shared.currentPairingFileURL() else {
      updateReadiness(status: "Not Ready", reason: "No pairing file imported.")
      completion(false, preparationFailureReason)
      return
    }

    guard let pairingData = try? Data(contentsOf: pairingFileURL) else {
      updateReadiness(status: "Not Ready", reason: "Could not read the pairing file.")
      completion(false, preparationFailureReason)
      return
    }

    startOperation { runner, finish in
      let host = self.activeHost
      host?.onPreparationProgress = { stage, fraction, detail in
        DispatchQueue.main.async {
          progress(fraction, detail ?? stage)
        }
      }
      host?.onPreparationFinished = { readiness, reason, txmPresent in
        DispatchQueue.main.async {
          let hintedReason = reason.map(appendingStikJITTroubleshootingHint)
          switch readiness {
          case "unreachable":
            self.updateReadiness(status: "Unreachable", reason: hintedReason)
            finish()
            completion(false, self.preparationFailureReason)
          case "ready":
            self.updateReadiness(status: "Ready", reason: nil)
            self.updateTXMStatus(txmPresent)
            finish()
            completion(true, nil)
          default:
            self.updateReadiness(status: "Not Ready", reason: hintedReason)
            finish()
            completion(false, self.preparationFailureReason)
          }
        }
      }
      runner.prepareDevice(withPairingData: pairingData)
    } failure: { error in
      self.updateReadiness(status: "Not Ready", reason: appendingStikJITTroubleshootingHint(error))
      completion(false, self.preparationFailureReason)
    }
  }

  @objc func resetCachedDDI(completion: @escaping (Bool, String?) -> Void) {
    guard #available(iOS 17.4, *) else {
      completion(false, "Requires iOS 17.4 or later.")
      return
    }

    startOperation { runner, finish in
      self.activeHost?.onResetFinished = { ok, error in
        DispatchQueue.main.async {
          if ok {
            self.invalidateReadiness()
          }
          finish()
          completion(ok, error)
        }
      }
      runner.resetCachedDDI()
    } failure: { error in
      completion(false, error)
    }
  }

  private func startOperation(
    request: @escaping (StikJITRunnerXPCProtocol, @escaping () -> Void) -> Void,
    failure: @escaping (String) -> Void
  ) {
    guard activeLauncher == nil else {
      failure("Another StikJIT operation is already in progress.")
      return
    }

    let host = DDIXPCHostBridge()
    let launcher = StikJITExtensionLauncher(host: host)
    activeHost = host
    activeLauncher = launcher

    let finish = { [weak self] in
      self?.activeLauncher?.invalidate()
      self?.activeLauncher = nil
      self?.activeHost = nil
    }

    launcher.launch { _, runner, error in
      DispatchQueue.main.async {
        if let error {
          finish()
          failure(error.localizedDescription)
          return
        }

        guard let runner else {
          finish()
          failure("Could not create the StikJIT runner proxy.")
          return
        }

        request(runner, finish)
      }
    }
  }

  private func updateReadiness(status: String, reason: String?) {
    preparationStatus = status
    preparationFailureReason = reason ?? ""
  }

  private func updateTXMStatus(_ txmPresent: NSNumber?) {
    if let txmPresent {
      txmStatus = txmPresent.boolValue ? "Detected" : "Not Detected"
    } else {
      txmStatus = "Unknown"
    }
  }
}
