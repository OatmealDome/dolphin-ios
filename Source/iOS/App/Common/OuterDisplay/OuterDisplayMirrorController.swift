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
      applyLayout()
    }
  }

  private static let layoutDefaultsKey = "outer_display_layout"
  private static let swapDefaultsKey = "outer_display_swap_halves"
  private static let stretchDefaultsKey = "outer_display_stretch"

  // MARK: Per-game profiles
  //
  // Layout, Swap and the picture settings are remembered per game. A game with no saved value
  // for a setting uses the default. While a game is running, changes from the in-game menu go
  // to that game's profile. Settings → Split-Duo edits the defaults, or any game's profile.
  // On/Off stays global.

  private static let profilesDefaultsKey = "outer_display_game_profiles"
  /// Stored in each profile so the Settings page can name games that aren't in the library.
  private static let titleProfileKey = "_title"

  /// The running game's ID (for example "GM4E01"), or nil outside a game.
  private(set) var currentGameID: String?
  /// The running game's name, for the menu.
  private(set) var currentGameTitle: String?

  /// Call when a game starts (or the title changes). Loads that game's saved settings.
  @objc(setGameID:title:) func setCurrentGame(id: String?, title: String?) {
    let id = (id?.isEmpty ?? true) ? nil : id
    guard id != currentGameID else { return }
    currentGameID = id
    currentGameTitle = (title?.isEmpty ?? true) ? id : title
    NSLog("[OuterDisplayMirror] Game %@ (%@), saved settings: %d", id ?? "none", currentGameTitle ?? "",
          hasProfile(game: id) ? 1 : 0)
    applyLayout()
  }

  /// Whether `game` has any settings of its own.
  func hasProfile(game: String?) -> Bool {
    guard let game, let profile = Self.profiles()[game] else { return false }
    return profile.keys.contains { $0 != Self.titleProfileKey }
  }

  /// Forget `game`'s own settings, so it uses the defaults again.
  func resetProfile(game: String?) {
    guard let game else { return }
    var all = Self.profiles()
    all[game] = nil
    UserDefaults.standard.set(all, forKey: Self.profilesDefaultsKey)
    applyLayout()
  }

  /// Make `game`'s own settings the defaults for every game without its own.
  func saveProfileAsDefaults(game: String?) {
    guard let game, let profile = Self.profiles()[game] else { return }
    for (key, value) in profile where key != Self.titleProfileKey {
      UserDefaults.standard.set(value, forKey: key)
    }
    applyLayout()
  }

  /// Games with their own settings, sorted by name.
  func savedGames() -> [(id: String, title: String)] {
    Self.profiles().keys.filter { hasProfile(game: $0) }
      .map { (id: $0, title: title(game: $0)) }
      .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
  }

  /// A game's name: remembered in its profile, else the ID.
  func title(game: String) -> String {
    if game == currentGameID, let title = currentGameTitle { return title }
    return Self.profiles()[game]?[Self.titleProfileKey] as? String ?? game
  }

  /// Remember a game's name (used before its profile exists, from the Settings page).
  func rememberTitle(_ title: String, game: String) {
    knownTitles[game] = title
  }

  private var knownTitles: [String: String] = [:]

  private static func profiles() -> [String: [String: Any]] {
    UserDefaults.standard.dictionary(forKey: profilesDefaultsKey) as? [String: [String: Any]] ?? [:]
  }

  private func storedValue(_ key: String, game: String?) -> Any? {
    if let game, let value = Self.profiles()[game]?[key] {
      return value
    }
    return UserDefaults.standard.object(forKey: key)
  }

  private func store(_ value: Any, _ key: String, game: String?) {
    if let game {
      var all = Self.profiles()
      all[game, default: [:]][key] = value
      let title = game == currentGameID ? currentGameTitle : knownTitles[game]
      if let title {
        all[game]?[Self.titleProfileKey] = title
      }
      UserDefaults.standard.set(all, forKey: Self.profilesDefaultsKey)
    } else {
      UserDefaults.standard.set(value, forKey: key)
    }
    applyLayout()
  }

  private func storedInt(_ key: String, game: String?) -> Int {
    (storedValue(key, game: game) as? NSNumber)?.intValue ?? 0
  }

  // MARK: Settings
  //
  // Each takes `game`: nil means the defaults; a game ID means that game's profile (falling
  // back to the defaults for anything it hasn't changed). The in-game menu uses the running game.

  /// Mirror, or split-screen with one half per display. Takes effect on the next frame.
  func layout(game: String?) -> OuterDisplayLayout {
    OuterDisplayLayout(rawValue: storedInt(Self.layoutDefaultsKey, game: game)) ?? .mirror
  }

  func setLayout(_ layout: OuterDisplayLayout, game: String?) {
    store(layout.rawValue, Self.layoutDefaultsKey, game: game)
  }

  /// In a split layout, put the first half (top or left) on the outer display instead.
  func swapHalves(game: String?) -> Bool {
    (storedValue(Self.swapDefaultsKey, game: game) as? NSNumber)?.boolValue ?? false
  }

  func setSwapHalves(_ swap: Bool, game: String?) {
    store(swap, Self.swapDefaultsKey, game: game)
  }

  private static let automaticKey = "outer_display_automatic"

  /// Mirror during menus and cutscenes, and switch to the right split layout automatically
  /// while the game is split-screen.
  func isAutomatic(game: String?) -> Bool {
    (storedValue(Self.automaticKey, game: game) as? NSNumber)?.boolValue ?? false
  }

  func setAutomatic(_ automatic: Bool, game: String?) {
    store(automatic, Self.automaticKey, game: game)
  }

  private static let mirrorWhilePausedKey = "outer_display_mirror_while_paused"

  /// Automatic mode: mirror while the game is paused (Start pressed mid-race).
  func mirrorsWhilePaused(game: String?) -> Bool {
    (storedValue(Self.mirrorWhilePausedKey, game: game) as? NSNumber)?.boolValue ?? true
  }

  func setMirrorsWhilePaused(_ mirror: Bool, game: String?) {
    store(mirror, Self.mirrorWhilePausedKey, game: game)
  }

  /// What automatic mode currently sees in the running game.
  var detectedLayout: OuterDisplayLayout { OuterDisplayMirrorView.detectedLayout() }

  private static let innerArrangementKey = "outer_display_inner_arrangement"

  /// 3- and 4-player layouts: players 1 and 2 side by side on the inner display, or one in each half.
  func innerArrangement(game: String?) -> OuterDisplayInnerArrangement {
    OuterDisplayInnerArrangement(rawValue: storedInt(Self.innerArrangementKey, game: game)) ?? .sideBySide
  }

  func setInnerArrangement(_ arrangement: OuterDisplayInnerArrangement, game: String?) {
    store(arrangement.rawValue, Self.innerArrangementKey, game: game)
  }

  static func isGrid(_ layout: OuterDisplayLayout) -> Bool {
    layout == .threePlayers || layout == .fourPlayers
  }

  /// Posted when settings that change the inner display's layout change.
  @objc static let layoutDidChangeNotification = Notification.Name("OuterDisplayLayoutDidChange")

  /// True when the game should use the whole inner display even in laptop posture, because the
  /// running game puts a player in each half of it.
  @objc var wantsWholeInnerDisplay: Bool {
    let effective = isAutomatic(game: currentGameID) ? detectedLayout : layout
    return isUserEnabled && Self.isGrid(effective) && innerArrangement(game: currentGameID) == .stacked
  }

  /// Fit (black bars) or Zoom to Fill (edges trimmed), per display.
  private static let pictureLinkedKey = "outer_display_picture_linked"

  /// Same for Both Screens: one Fit/Zoom and stretch setting for both displays. While on, the
  /// outer display's values are used for both, and changes are saved to both (so turning it off
  /// leaves both screens where they were).
  func isPictureLinked(game: String?) -> Bool {
    (storedValue(Self.pictureLinkedKey, game: game) as? NSNumber)?.boolValue ?? false
  }

  func setPictureLinked(_ linked: Bool, game: String?) {
    if linked {
      // Start both screens from the outer screen's settings.
      store(scaling(outer: true, game: game).rawValue, Self.scalingKey(outer: false), game: game)
      store(stretchAmount(outer: true, game: game), Self.stretchAmountKey(outer: false), game: game)
    }
    store(linked, Self.pictureLinkedKey, game: game)
  }

  func scaling(outer: Bool, game: String?) -> OuterDisplayScaling {
    let outer = outer || isPictureLinked(game: game)
    return OuterDisplayScaling(rawValue: storedInt(Self.scalingKey(outer: outer), game: game)) ?? .fit
  }

  func setScaling(_ scaling: OuterDisplayScaling, outer: Bool, game: String?) {
    if isPictureLinked(game: game) {
      store(scaling.rawValue, Self.scalingKey(outer: false), game: game)
      store(scaling.rawValue, Self.scalingKey(outer: true), game: game)
    } else {
      store(scaling.rawValue, Self.scalingKey(outer: outer), game: game)
    }
  }

  /// How far the picture is stretched toward the display's shape, 0...1, per display.
  func stretchAmount(outer: Bool, game: String?) -> Float {
    let outer = outer || isPictureLinked(game: game)
    if let value = storedValue(Self.stretchAmountKey(outer: outer), game: game) as? NSNumber {
      return value.floatValue
    }
    // Earlier builds had a single on/off "Stretch to Fill".
    return UserDefaults.standard.bool(forKey: Self.stretchDefaultsKey) ? 1 : 0
  }

  func setStretchAmount(_ amount: Float, outer: Bool, game: String?) {
    let amount = min(max(amount, 0), 1)
    if isPictureLinked(game: game) {
      store(amount, Self.stretchAmountKey(outer: false), game: game)
      store(amount, Self.stretchAmountKey(outer: true), game: game)
    } else {
      store(amount, Self.stretchAmountKey(outer: outer), game: game)
    }
  }

  // The running game's settings (the defaults outside a game).
  var layout: OuterDisplayLayout {
    get { layout(game: currentGameID) }
    set { setLayout(newValue, game: currentGameID) }
  }

  var swapHalves: Bool {
    get { swapHalves(game: currentGameID) }
    set { setSwapHalves(newValue, game: currentGameID) }
  }

  var isAutomatic: Bool {
    get { isAutomatic(game: currentGameID) }
    set { setAutomatic(newValue, game: currentGameID) }
  }

  var innerArrangement: OuterDisplayInnerArrangement {
    get { innerArrangement(game: currentGameID) }
    set { setInnerArrangement(newValue, game: currentGameID) }
  }

  func scaling(outer: Bool) -> OuterDisplayScaling { scaling(outer: outer, game: currentGameID) }
  func setScaling(_ scaling: OuterDisplayScaling, outer: Bool) { setScaling(scaling, outer: outer, game: currentGameID) }
  func stretchAmount(outer: Bool) -> Float { stretchAmount(outer: outer, game: currentGameID) }
  func setStretchAmount(_ amount: Float, outer: Bool) { setStretchAmount(amount, outer: outer, game: currentGameID) }

  private static func scalingKey(outer: Bool) -> String {
    outer ? "outer_display_scaling_outer" : "outer_display_scaling_inner"
  }

  private static func stretchAmountKey(outer: Bool) -> String {
    outer ? "outer_display_stretch_amount_outer" : "outer_display_stretch_amount_inner"
  }

  /// "Split-Duo" submenu for the in-game menu: Off / Mirror / Split modes, plus Swap and Stretch.
  /// Rebuilt every time it opens, so the checkmarks are current.
  @objc func makeMenu() -> UIMenu {
    UIMenu(title: "Split-Duo", image: UIImage(systemName: "rectangle.on.rectangle"), children: [
      UIDeferredMenuElement.uncached { [weak self] completion in
        MainActor.assumeIsolated {
          completion(self?.menuElements() ?? [])
        }
      }
    ])
  }

  private func menuElements() -> [UIMenuElement] {
    func choice(_ title: String, _ image: String, selected: Bool, _ handler: @escaping @MainActor () -> Void) -> UIAction {
      UIAction(title: title, image: UIImage(systemName: image), state: selected ? .on : .off) { _ in
        MainActor.assumeIsolated { handler() }
      }
    }

    let on = isUserEnabled

    let modes = UIMenu(options: .displayInline, children: [
      choice("Off", "rectangle.slash", selected: !on) { self.isUserEnabled = false },
      choice("Mirror", "rectangle.on.rectangle", selected: on && layout == .mirror) {
        self.layout = .mirror
        self.isUserEnabled = true
      },
      choice("Split: Top & Bottom", "rectangle.split.1x2", selected: on && layout == .splitTopBottom) {
        self.layout = .splitTopBottom
        self.isUserEnabled = true
      },
      choice("Split: Left & Right", "rectangle.split.2x1", selected: on && layout == .splitLeftRight) {
        self.layout = .splitLeftRight
        self.isUserEnabled = true
      },
      choice("3 Players", "rectangle.split.2x2", selected: on && layout == .threePlayers) {
        self.layout = .threePlayers
        self.isUserEnabled = true
      },
      choice("4 Players", "rectangle.split.2x2.fill", selected: on && layout == .fourPlayers) {
        self.layout = .fourPlayers
        self.isUserEnabled = true
      },
    ])

    let automatic = UIAction(title: "Automatic", image: UIImage(systemName: "wand.and.stars"),
                             state: isAutomatic ? .on : .off) { _ in
      MainActor.assumeIsolated { self.isAutomatic.toggle() }
    }
    if #available(iOS 16.0, *) {
      automatic.subtitle = isAutomatic
        ? "Now: \(Self.detectedDescription(detectedLayout))"
        : "Mirror in menus, split during split-screen"
    }

    var optionItems: [UIMenuElement] = [automatic]
    if isAutomatic {
      let paused = mirrorsWhilePaused(game: currentGameID)
      optionItems.append(choice("Mirror While Paused", "pause.rectangle", selected: paused) {
        self.setMirrorsWhilePaused(!paused, game: self.currentGameID)
      })
    }
    optionItems += [
      choice("Swap Screens", "arrow.left.arrow.right", selected: swapHalves) { self.swapHalves.toggle() },
    ]
    if Self.isGrid(layout) || isAutomatic {
      let arrangement = innerArrangement
      optionItems.append(UIMenu(title: "Players 1 & 2 (Inner Screen)", image: UIImage(systemName: "rectangle.split.2x1"), children: [
        choice("Side by Side", "rectangle.split.2x1", selected: arrangement == .sideBySide) {
          self.innerArrangement = .sideBySide
        },
        choice("Top & Bottom Halves", "rectangle.split.1x2", selected: arrangement == .stacked) {
          self.innerArrangement = .stacked
        },
      ]))
    }
    let options = UIMenu(options: .displayInline, children: optionItems)

    // Picture shape, per display. Menus can't hold sliders, so stretch has presets here;
    // Settings → Split-Duo has a slider for anything in between.
    func pictureMenu(_ title: String, _ image: String, outer: Bool) -> UIMenu {
      let scaling = self.scaling(outer: outer)
      let amount = self.stretchAmount(outer: outer)
      let fitZoom = UIMenu(options: .displayInline, children: [
        choice("Fit (Black Bars)", "rectangle.center.inset.filled", selected: scaling == .fit) {
          self.setScaling(.fit, outer: outer)
        },
        choice("Zoom to Fill (Trim Edges)", "plus.magnifyingglass", selected: scaling == .zoom) {
          self.setScaling(.zoom, outer: outer)
        },
      ])
      let presets: [(String, Float)] = [("No Stretch", 0), ("Stretch 25%", 0.25), ("Stretch 50%", 0.5),
                                        ("Stretch 75%", 0.75), ("Full Stretch", 1)]
      let stretches = UIMenu(options: .displayInline, children: presets.map { title, value in
        choice(title, "arrow.left.and.right", selected: abs(amount - value) < 0.01) {
          self.setStretchAmount(value, outer: outer)
        }
      })
      let menu = UIMenu(title: title, image: UIImage(systemName: image), children: [fitZoom, stretches])
      menu.subtitle = Self.describe(scaling: scaling, stretch: amount)
      return menu
    }

    let linked = isPictureLinked(game: currentGameID)
    let linkToggle = choice("Same for Both Screens", "link", selected: linked) {
      self.setPictureLinked(!linked, game: self.currentGameID)
    }
    let pictures = UIMenu(options: .displayInline, children: linked
      ? [pictureMenu("Picture (Both Screens)", "rectangle.on.rectangle", outer: true), linkToggle]
      : [pictureMenu("Outer Screen Picture", "iphone.gen3", outer: true),
         pictureMenu("Inner Screen Picture (Split)", "rectangle.portrait.split.2x1", outer: false),
         linkToggle])

    var elements: [UIMenuElement] = [modes, options, pictures]

    if let title = currentGameTitle {
      let saved = self.hasProfile(game: currentGameID)
      let reset = UIAction(title: "Reset This Game to Defaults", image: UIImage(systemName: "arrow.counterclockwise"),
                           attributes: saved ? [] : [.disabled]) { _ in
        MainActor.assumeIsolated { self.resetProfile(game: self.currentGameID) }
      }
      let makeDefault = UIAction(title: "Use These Settings for All Games", image: UIImage(systemName: "square.and.arrow.down"),
                                 attributes: saved ? [] : [.disabled]) { _ in
        MainActor.assumeIsolated { self.saveProfileAsDefaults(game: self.currentGameID) }
      }
      let gameMenu = UIMenu(title: saved ? "Saved for \(title)" : "Changes are saved for \(title)",
                            options: .displayInline, children: [reset, makeDefault])
      elements.append(gameMenu)
    }

    return elements
  }

  /// What automatic mode sees, for the menu.
  static func detectedDescription(_ layout: OuterDisplayLayout) -> String {
    switch layout {
    case .splitTopBottom: return "2 players, top & bottom"
    case .splitLeftRight: return "2 players, left & right"
    case .threePlayers: return "3 players"
    case .fourPlayers: return "4 players"
    default: return OuterDisplayMirrorView.isPaused() ? "mirroring (paused)" : "mirroring (not split-screen)"
    }
  }

  /// For example "Fit, 50% stretch".
  static func describe(scaling: OuterDisplayScaling, stretch: Float) -> String {
    let mode = scaling == .zoom ? "Zoom to Fill" : "Fit"
    let percent = Int((stretch * 100).rounded())
    return percent == 0 ? mode : "\(mode), \(percent)% stretch"
  }

  private func applyLayout() {
    OuterDisplayMirrorView.setLayout(layout, swapHalves: swapHalves, innerArrangement: innerArrangement)
    OuterDisplayMirrorView.setAutomatic(isAutomatic)
    OuterDisplayMirrorView.setMirrorWhilePaused(mirrorsWhilePaused(game: currentGameID))
    for outer in [false, true] {
      OuterDisplayMirrorView.setScaling(scaling(outer: outer), stretch: stretchAmount(outer: outer), forOuterDisplay: outer)
    }
    NotificationCenter.default.post(name: Self.layoutDidChangeNotification, object: self)
  }

  private weak var hostViewController: UIViewController?
  private var registration: AnyObject?  // UISceneAccessoryRegistration (iOS 27.1+)
  private let camera = CameraKeepAlive()

  /// Call from the emulation view controller once it is on screen.
  @objc func attach(to viewController: UIViewController) {
    hostViewController = viewController
    applyLayout()
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
