// Copyright 2025 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import Foundation

@objc(StikJITRunnerXPCProtocol)
protocol StikJITRunnerXPCProtocol {
  func enableJIT(forParentPID pid: Int32, pairingData: Data, scriptIdentifier: String)
}

@objc(StikJITHostXPCProtocol)
protocol StikJITHostXPCProtocol {
  func jitLog(_ line: String)
  func jitFinished(_ ok: Bool, error: String?)
}

private let kListenerEndpointKey = "DOLStikJITListenerEndpoint"

@objc(JITEnablerRequestHandler)
final class JITEnablerRequestHandler: NSObject, NSExtensionRequestHandling, StikJITRunnerXPCProtocol {
  private var connection: NSXPCConnection?
  private var host: StikJITHostXPCProtocol?

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

  func enableJIT(forParentPID pid: Int32, pairingData: Data, scriptIdentifier: String) {
    let host = self.host
    let script: StikJIT.Script = scriptIdentifier == "universal" ? .universal : .legacy
    host?.jitLog("enableJIT pid=\(pid) script=\(scriptIdentifier) pairingBytes=\(pairingData.count)")

    Thread.detachNewThread {
      let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("jitenabler-pairing-\(getpid()).plist")
      do {
        try pairingData.write(to: tmp, options: .atomic)
        defer { try? FileManager.default.removeItem(at: tmp) }
        host?.jitLog("wrote \(pairingData.count) pairing bytes to \(tmp.path); attaching to pid \(pid)")
        try StikJIT.enableJIT(targetPID: pid, pairingFile: tmp, script: script) { line in
          host?.jitLog(line)
        }
        host?.jitFinished(true, error: nil)
      } catch {
        host?.jitLog("enableJIT failed: \(String(describing: error))")
        host?.jitFinished(false, error: error.localizedDescription)
      }
    }
  }
}
