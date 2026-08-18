// Copyright 2025 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import Foundation
import StikJIT

@objc(StikJITRunnerXPCProtocol)
protocol StikJITRunnerXPCProtocol {
  func detectTXM()
  func prepareDevice(pairingData: Data)
  func resetCachedDDI()
  func enableJIT(forParentPID pid: Int32, pairingData: Data, forceScript: Bool)
}

@objc(StikJITHostXPCProtocol)
protocol StikJITHostXPCProtocol {
  func txmDetectionFinished(_ txmPresent: NSNumber?)
  func preparationProgress(_ stage: String, fraction: Double, detail: String?)
  func preparationFinished(_ readiness: String, reason: String?, txmPresent: NSNumber?)
  func ddiResetFinished(_ ok: Bool, error: String?)
  func jitLog(_ line: String)
  func jitFinished(_ ok: Bool, error: String?)
}

private let kListenerEndpointKey = "DOLStikJITListenerEndpoint"
private let backendSelectedScript: StikJIT.Script = .legacy

@objc(JITEnablerRequestHandler)
final class JITEnablerRequestHandler: NSObject, NSExtensionRequestHandling, StikJITRunnerXPCProtocol {
  private let operationQueue = DispatchQueue(label: "org.dolphinios.jitenabler.stikjit", qos: .userInitiated)
  private var connection: NSXPCConnection?
  private var host: StikJITHostXPCProtocol?

  private let paths: DDIPaths = {
    let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
    return DDIPaths.default(in: library.appendingPathComponent("StikJIT"))
  }()

  func beginRequest(with context: NSExtensionContext) {
    NSLog("[JITEnabler] helper beginRequest")

    guard let item = context.inputItems.first as? NSExtensionItem,
          let endpoint = item.userInfo?[kListenerEndpointKey] as? NSXPCListenerEndpoint else {
      NSLog("[JITEnabler] missing listener endpoint")
      context.cancelRequest(withError: NSError(domain: "JITEnablerRequestHandler", code: 1))
      return
    }

    let connection = NSXPCConnection(listenerEndpoint: endpoint)
    connection.exportedInterface = NSXPCInterface(with: StikJITRunnerXPCProtocol.self)
    connection.exportedObject = self
    connection.remoteObjectInterface = NSXPCInterface(with: StikJITHostXPCProtocol.self)
    connection.resume()
    self.connection = connection
    self.host = connection.remoteObjectProxyWithErrorHandler { _ in } as? StikJITHostXPCProtocol
    host?.jitLog("StikJIT runner alive, pid \(getpid())")
  }

  func detectTXM() {
    let host = self.host
    operationQueue.async {
      host?.txmDetectionFinished(StikJIT.isTXMPresent.map(NSNumber.init(value:)))
    }
  }

  func prepareDevice(pairingData: Data) {
    let host = self.host
    operationQueue.async { [paths] in
      do {
        try Self.withTemporaryPairingFile(pairingData) { pairingFile in
          let readiness = StikJIT.prepareDevice(
            pairingFile: pairingFile,
            paths: paths,
            configuration: .default
          ) { stage in
            let update = Self.preparationUpdate(for: stage)
            host?.preparationProgress(update.stage, fraction: update.fraction, detail: update.detail)
          }

          switch readiness {
          case .unreachable(let reason):
            host?.preparationFinished("unreachable", reason: reason, txmPresent: nil)
          case .preparationFailed(let reason):
            host?.preparationFinished("preparationFailed", reason: reason, txmPresent: nil)
          case .ready(let securityState):
            host?.preparationFinished(
              "ready",
              reason: nil,
              txmPresent: securityState.isTXMPresent.map(NSNumber.init(value:)))
          }
        }
      } catch {
        host?.preparationFinished("preparationFailed", reason: error.localizedDescription, txmPresent: nil)
      }
    }
  }

  func resetCachedDDI() {
    let host = self.host
    operationQueue.async { [paths] in
      do {
        try StikJIT.resetCachedDDI(at: paths)
        host?.ddiResetFinished(true, error: nil)
      } catch {
        host?.ddiResetFinished(false, error: error.localizedDescription)
      }
    }
  }

  func enableJIT(forParentPID pid: Int32, pairingData: Data, forceScript: Bool) {
    let host = self.host
    operationQueue.async { [paths] in
      do {
        try Self.withTemporaryPairingFile(pairingData) { pairingFile in
          try StikJIT.enableJIT(
            targetPID: pid,
            pairingFile: pairingFile,
            ddiPaths: paths,
            script: backendSelectedScript,
            forceScript: forceScript,
            preparationProgress: { stage in
              let update = Self.preparationUpdate(for: stage)
              if let detail = update.detail {
                host?.jitLog(detail)
              } else {
                host?.jitLog(update.stage)
              }
            },
            progress: { line in
              host?.jitLog(line)
            })
        }
        host?.jitFinished(true, error: nil)
      } catch {
        host?.jitLog("enableJIT failed: \(error.localizedDescription)")
        host?.jitFinished(false, error: error.localizedDescription)
      }
    }
  }

  private static func withTemporaryPairingFile<T>(_ data: Data, operation: (URL) throws -> T) throws -> T {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("jitenabler-pairing-\(UUID().uuidString).plist")
    try data.write(to: url, options: .atomic)
    defer { try? FileManager.default.removeItem(at: url) }
    return try operation(url)
  }

  private static func preparationUpdate(for stage: StikJIT.PreparationStage) ->
    (stage: String, fraction: Double, detail: String?) {
    switch stage {
    case .checkingReachability:
      return ("Checking Network", 0, nil)
    case .checkingDDI:
      return ("Checking DDI", 0, nil)
    case .downloadingDDI(let fraction, let status):
      return ("Downloading", fraction, status)
    case .mountingDDI(let fraction):
      return ("Mounting", fraction, nil)
    case .verifyingDDI:
      return ("Verifying", 1, nil)
    case .ready:
      return ("Ready", 1, nil)
    }
  }
}
