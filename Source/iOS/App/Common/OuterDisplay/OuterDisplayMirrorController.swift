// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

// Mirrors the game onto iPhone Duo's outer display while the phone is open.
//
// iOS 27.1 only lets an app draw on the outer display (while it is open on the inner
// display) through a *camera capture scene accessory*, and only while a camera capture
// session is running. So this file:
//   1. runs a tiny, frame-dropping camera session to satisfy that requirement,
//   2. registers a camera capture accessory on the emulation view controller, and
//   3. puts an OuterDisplayMirrorView in the accessory's scene, which copies every frame.
//
// The system decides when the accessory is shown and can withdraw it at any time
// (phone folded, app in background, camera interrupted). The mirror view stops drawing
// when that happens, so the game itself is never affected.

#if os(iOS)

import AVFoundation
import UIKit

@MainActor @objc final class OuterDisplayMirrorController: NSObject {
  @objc static let shared = OuterDisplayMirrorController()

  /// Set to false in UserDefaults to turn the feature off without rebuilding.
  static let enabledDefaultsKey = "outer_display_mirror_enabled"

  /// Whether the user wants the outer screen mirror. Remembered between launches.
  /// Setting it takes effect immediately (turning it off also stops the camera keep-alive).
  @objc var isUserEnabled: Bool {
    get { UserDefaults.standard.object(forKey: Self.enabledDefaultsKey) as? Bool ?? true }
    set {
      UserDefaults.standard.set(newValue, forKey: Self.enabledDefaultsKey)
      NSLog("[OuterDisplayMirror] Turned %@ by the user", newValue ? "on" : "off")
      update()
    }
  }

  private weak var hostViewController: UIViewController?
  private var registration: AnyObject?  // UISceneAccessoryRegistration (iOS 27.1+)
  private let camera = CameraKeepAlive()

  /// Call from the emulation view controller once it is on screen.
  @objc func attach(to viewController: UIViewController) {
    hostViewController = viewController
    update()
  }

  /// Call when the emulation view controller goes away.
  @objc func detach() {
    tearDown()
    hostViewController = nil
  }

  /// Call when the emulation view changes size (for example the phone was folded or opened).
  @objc func hostSizeDidChange() {
    // Let the new size settle before checking which display we are on.
    DispatchQueue.main.async { self.update() }
  }

  // MARK: - Private

  private func update() {
    guard isUserEnabled, let host = hostViewController, Self.isOnInnerDisplay(host) else {
      tearDown()
      return
    }

    guard #available(iOS 27.1, *) else { return }

    if registration == nil {
      // The system assigns the accessory's scene the .windowCameraCaptureAccessory role itself
      // (UIWindowScene.h: "Clients do not set it directly"), so only the delegate class is set here.
      let configuration = UISceneConfiguration()
      configuration.delegateClass = OuterDisplayMirrorSceneDelegate.self

      let accessory = UISceneAccessory.cameraCapture(sceneConfiguration: configuration)
      let newRegistration = host.registerSceneAccessory(accessory)
      NSLog("[OuterDisplayMirror] Registered camera capture accessory (available: %d)", newRegistration.isAvailable ? 1 : 0)
      registration = newRegistration
    }

    camera.start()
  }

  private func tearDown() {
    camera.stop()

    if #available(iOS 27.1, *), let registration = registration as? UISceneAccessoryRegistration {
      hostViewController?.unregisterSceneAccessory(registration)
    }
    registration = nil
  }

  /// The accessory only exists while the app is on the large inner display. The inner
  /// display is close to square; the outer display (and every other iPhone) is tall and
  /// narrow. Checking the shape avoids running the camera when it can't help.
  private static func isOnInnerDisplay(_ viewController: UIViewController) -> Bool {
    guard UIDevice.current.userInterfaceIdiom == .phone,
          let bounds = viewController.view.window?.bounds,
          bounds.width > 0, bounds.height > 0 else {
      return false
    }

    let longSide = max(bounds.width, bounds.height)
    let shortSide = min(bounds.width, bounds.height)
    return longSide / shortSide < 1.7
  }
}

// MARK: - Accessory scene

@available(iOS 27.1, *)
final class OuterDisplayMirrorSceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?
  private let mirrorView = OuterDisplayMirrorView(frame: .zero)

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = scene as? UIWindowScene else { return }

    let viewController = UIViewController()
    viewController.view = mirrorView

    let window = UIWindow(windowScene: windowScene)
    window.backgroundColor = .black
    window.rootViewController = viewController
    window.makeKeyAndVisible()
    self.window = window

    mirrorView.startMirroring()
  }

  func sceneWillEnterForeground(_ scene: UIScene) {
    mirrorView.startMirroring()
  }

  func sceneDidEnterBackground(_ scene: UIScene) {
    mirrorView.stopMirroring()
  }

  func sceneDidDisconnect(_ scene: UIScene) {
    mirrorView.stopMirroring()
    window = nil
  }
}

// MARK: - Camera keep-alive

/// A camera session that exists only so iOS will show the outer display accessory.
/// It uses the lowest resolution and frame rate the camera offers and throws every frame away.
private final class CameraKeepAlive: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
  private let session = AVCaptureSession()
  private let queue = DispatchQueue(label: "org.dolphin-emu.outer-display-camera")
  private var isConfigured = false
  private var wantsRunning = false

  func start() {
    queue.async {
      self.wantsRunning = true

      switch AVCaptureDevice.authorizationStatus(for: .video) {
      case .authorized:
        self.startOnQueue()
      case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { granted in
          guard granted else { return }
          self.queue.async { self.startOnQueue() }
        }
      default:
        NSLog("[OuterDisplayMirror] Camera access denied; outer display mirroring is unavailable")
      }
    }
  }

  func stop() {
    queue.async {
      self.wantsRunning = false
      if self.session.isRunning {
        self.session.stopRunning()
      }
    }
  }

  private func startOnQueue() {
    guard wantsRunning, !session.isRunning else { return }

    if !isConfigured {
      guard configure() else { return }
      isConfigured = true
    }

    session.startRunning()
  }

  private func configure() -> Bool {
    guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            ?? AVCaptureDevice.default(for: .video),
          let input = try? AVCaptureDeviceInput(device: device) else {
      NSLog("[OuterDisplayMirror] No camera available")
      return false
    }

    session.beginConfiguration()

    // Don't let the camera take over the app's audio session (the game's sound).
    session.automaticallyConfiguresApplicationAudioSession = false

    if session.canSetSessionPreset(.low) {
      session.sessionPreset = .low
    }

    let output = AVCaptureVideoDataOutput()
    output.alwaysDiscardsLateVideoFrames = true
    output.setSampleBufferDelegate(self, queue: queue)

    guard session.canAddInput(input), session.canAddOutput(output) else {
      session.commitConfiguration()
      return false
    }
    session.addInput(input)
    session.addOutput(output)
    session.commitConfiguration()

    // Run the camera as slowly as it allows to save power. (maxFrameDuration = lowest frame rate.)
    if let slowest = device.activeFormat.videoSupportedFrameRateRanges.map(\.maxFrameDuration).max(),
       (try? device.lockForConfiguration()) != nil {
      device.activeVideoMinFrameDuration = slowest
      device.activeVideoMaxFrameDuration = slowest
      device.unlockForConfiguration()
    }

    return true
  }

  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    // Frames are not needed.
  }
}

#endif
