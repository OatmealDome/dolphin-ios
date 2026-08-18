// Copyright 2025 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import Foundation

private let kRequestTimeout: TimeInterval = 300
private var isAttemptingStikJIT = false
private var currentAttemptID = 0
private var activeLauncher: StikJITExtensionLauncher?
private var activeHost: StikJITHostBridge?

private class StikJITHostBridge: NSObject, StikJITHostXPCProtocol {
  var onLog: ((String) -> Void)?
  var onFinished: ((Bool, String?) -> Void)?

  func txmDetectionFinished(_ txmPresent: NSNumber?) {}
  func preparationProgress(_ stage: String, fraction: Double, detail: String?) {}
  func preparationFinished(_ readiness: String, reason: String?, txmPresent: NSNumber?) {}
  func ddiResetFinished(_ ok: Bool, error: String?) {}

  func jitLog(_ line: String) {
    onLog?(line)
  }

  func jitFinished(_ ok: Bool, error: String?) {
    onFinished?(ok, error)
  }
}

extension JitManager {
  @objc var isStikJITRunning: Bool {
    isAttemptingStikJIT
  }

  @objc func acquireJitByStikJIT() {
    guard #available(iOS 17.4, *) else {
      return
    }

    guard !StikJITManager.shared.isRunningInLiveContainer,
          StikJITManager.shared.jitLaunchMode == .builtInStikJIT,
          let pairingFileURL = StikJITManager.shared.currentPairingFileURL(),
          !isAttemptingStikJIT else {
      return
    }

    guard let pairingData = try? Data(contentsOf: pairingFileURL) else {
      self.acquisitionError = "StikJIT failed to enable JIT: could not read the pairing file."
      return
    }

    isAttemptingStikJIT = true
    currentAttemptID += 1
    let attemptID = currentAttemptID
    let targetPID = Int32(getpid())

    let host = StikJITHostBridge()
    let launcher = StikJITExtensionLauncher(host: host)
    activeHost = host
    activeLauncher = launcher

    func finish(ok: Bool, message: String?) {
      guard attemptID == currentAttemptID else { return }
      isAttemptingStikJIT = false
      activeLauncher?.invalidate()
      activeLauncher = nil
      activeHost = nil

      if !ok {
        let hintedMessage = appendingStikJITTroubleshootingHint(message ?? "Unknown error")
        DispatchQueue.main.async { [weak self] in
          self?.acquisitionError = "StikJIT failed to enable JIT: \(hintedMessage)"
        }
      }
    }

    host.onLog = { line in
      NSLog("[StikJIT runner] %@", line)
    }
    host.onFinished = { ok, message in
      finish(ok: ok, message: message)
    }

    launcher.launch { _, runner, error in
      if let error {
        finish(ok: false, message: error.localizedDescription)
        return
      }

      guard let runner else {
        finish(ok: false, message: "Could not create the StikJIT runner proxy.")
        return
      }

      NSLog("[StikJIT] runner connected; attaching to pid %d", targetPID)
      runner.enableJIT(
        forParentPID: targetPID,
        pairingData: pairingData,
        forceScript: StikJITManager.shared.forceJITScriptEnabled)
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + kRequestTimeout) {
      guard attemptID == currentAttemptID, isAttemptingStikJIT else { return }
      finish(ok: false, message: "the JITEnabler extension did not respond in time. Make sure you are connected to Wi-Fi/Airplane Mode and LocalDevVPN, and your pairing file is valid.")
    }
  }
}
