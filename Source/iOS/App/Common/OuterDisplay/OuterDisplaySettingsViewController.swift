// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#if os(iOS)

import UIKit

/// Settings → Split-Duo.
///
/// Without a game, this page turns iPhone Duo outer display support on or off, edits the
/// default layout and picture settings, and lists the games that have their own settings.
/// With a game, it edits that game's own settings (anything it hasn't changed shows the default).
/// Changes apply immediately, including to a game that is already running.
final class OuterDisplaySettingsViewController: UITableViewController {
  private enum Section {
    case enable
    case automatic
    case layout
    case outerPicture
    case innerPicture
    case innerArrangement
    case options
    case games
    case gameActions
  }

  private let layouts: [(title: String, subtitle: String, value: OuterDisplayLayout)] = [
    ("Mirror", "Both screens show the whole game.", .mirror),
    ("Split: Top & Bottom", "Most 2-player games. 4-player games put one row on each screen.", .splitTopBottom),
    ("Split: Left & Right", "Games that put players side by side.", .splitLeftRight),
    ("3 Players", "2x2 grid: players 1 & 2 on the inner screen, player 3 on the outer screen.", .threePlayers),
    ("4 Players", "2x2 grid: players 1 & 2 on the inner screen, players 3 & 4 side by side on the outer screen.", .fourPlayers),
  ]

  private let arrangements: [(title: String, subtitle: String, value: OuterDisplayInnerArrangement)] = [
    ("Side by Side", "In laptop posture, both above the fold.", .sideBySide),
    ("Top & Bottom Halves", "In laptop posture, one above and one below the fold (where the touch controls usually are).", .stacked),
  ]

  private let scalings: [(title: String, subtitle: String, value: OuterDisplayScaling)] = [
    ("Fit", "Whole picture, black bars where the shapes differ.", .fit),
    ("Zoom to Fill", "No black bars; trims the picture's edges.", .zoom),
  ]

  // Rows in a picture section: the scaling choices, then the stretch slider.
  private var stretchRow: Int { scalings.count }

  /// nil: the defaults page. Otherwise the game whose settings this page edits.
  private let gameID: String?
  private var savedGames: [(id: String, title: String)] = []

  private var controller: OuterDisplayMirrorController { .shared }

  init(gameID: String? = nil, gameTitle: String? = nil) {
    self.gameID = gameID
    super.init(style: .insetGrouped)
    title = gameTitle ?? "Split-Duo"
  }

  required init?(coder: NSCoder) {
    gameID = nil
    super.init(coder: coder)
    title = "Split-Duo"
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    // A game's page may have added or reset a game.
    savedGames = controller.savedGames()
    tableView.reloadData()
  }

  private var linked: Bool { controller.isPictureLinked(game: gameID) }

  // The "Same for Both Screens" switch is the last row of the (outer) picture section.
  private var linkRow: Int { scalings.count + 1 }

  private var sections: [Section] {
    let all = sectionsIncludingBothPictures
    return linked ? all.filter { $0 != .innerPicture } : all
  }

  private var sectionsIncludingBothPictures: [Section] {
    if gameID != nil {
      return [.automatic, .layout, .innerArrangement, .outerPicture, .innerPicture, .options, .gameActions]
    }
    // Hide everything else while the feature is off.
    return controller.isUserEnabled ? [.enable, .automatic, .layout, .innerArrangement, .outerPicture, .innerPicture, .options, .games] : [.enable]
  }

  private func sectionAt(_ index: Int) -> Section { sections[index] }

  override func numberOfSections(in tableView: UITableView) -> Int { sections.count }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection index: Int) -> Int {
    switch sectionAt(index) {
    case .enable: return 1
    case .automatic: return controller.isAutomatic(game: gameID) ? 2 : 1
    case .layout: return layouts.count
    case .innerArrangement: return arrangements.count
    case .outerPicture: return scalings.count + 2
    case .innerPicture: return scalings.count + 1
    case .options: return 1
    case .games: return savedGames.count + 1  // + "Add Game…"
    case .gameActions: return 1
    }
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection index: Int) -> String? {
    let defaults = gameID == nil
    switch sectionAt(index) {
    case .enable, .gameActions: return nil
    case .automatic: return gameID == nil ? "Default Mode" : "Mode"
    case .layout:
      if controller.isAutomatic(game: gameID) {
        return "Layout When Automatic Is Off"
      }
      return defaults ? "Default Layout" : "Layout"
    case .innerArrangement: return "Players 1 & 2 (Inner Screen)"
    case .outerPicture:
      if linked {
        return defaults ? "Default Picture (Both Screens)" : "Picture (Both Screens)"
      }
      return defaults ? "Default Outer Screen Picture" : "Outer Screen Picture"
    case .innerPicture: return defaults ? "Default Inner Screen Picture" : "Inner Screen Picture"
    case .options: return "Options"
    case .games: return "Game Settings"
    }
  }

  override func tableView(_ tableView: UITableView, titleForFooterInSection index: Int) -> String? {
    switch sectionAt(index) {
    case .enable:
      return "iPhone Duo only. Shows the game on the outer screen while the phone is open. "
        + "iOS only allows this while the camera is on, so the camera runs at its lowest setting "
        + "during games. No images are saved or sent."
    case .layout:
      if gameID != nil {
        return "These settings are used only for this game. Anything you haven't changed for it "
          + "follows the defaults."
      }
      return "In split layouts each player needs their own controller, because the outer screen "
        + "can't take touch input.\n\nThese are the defaults for every game without its own settings."
    case .automatic:
      return "Automatic shows the whole game on both screens during menus and cutscenes, and switches "
        + "to split screens by itself when the game goes split-screen. It picks 2, 3 or 4 players from "
        + "what the game draws, and uses the settings below for how the views are arranged. "
        + "If a 3-player race is shown as 4 players, choose 3 Players below.\n\n"
        + "Mirror While Paused: pressing Start during split-screen shows the pause menu whole on both "
        + "screens; Start, A or B (closing or choosing from the menu) splits them again."
    case .innerArrangement:
      return "3 and 4 Players layouts only. Works whether or not the touch controls are showing; with everyone on controllers they are normally hidden. Swap Screens: in 3 Players it switches players 1 and 2 (player 3 always stays outside); in 4 Players it swaps the rows, so players 3 and 4 go inside."
    case .outerPicture:
      return "Stretch pulls the picture toward the screen's shape. A little stretch is hard to notice "
        + "and shrinks the black bars (or the trimmed edges) a lot."
        + (linked
          ? "\n\nSame for Both Screens is on: these settings apply to the outer screen and to the inner "
            + "screen in split layouts."
          : "\n\nTurn on Same for Both Screens to set both screens at once.")
    case .innerPicture:
      return "Split layouts only. In Mirror mode the inner screen uses Dolphin's own aspect ratio setting. "
        + "Zoom to Fill trims a lot here, because a split half is much wider than the inner screen."
    case .options:
      return nil
    case .games:
      return "Games listed here use their own settings instead of the defaults. Changes made during a "
        + "game from the in-game menu's Split-Duo item also add the game here."
    case .gameActions:
      return "Use These for All Games copies this game's settings to the defaults."
    }
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let section = sectionAt(indexPath.section)
    switch section {
    case .enable:
      return switchCell(title: "Use Outer Screen", isOn: controller.isUserEnabled) { [weak self] isOn in
        guard let self else { return }
        self.controller.isUserEnabled = isOn
        self.tableView.reloadData()
      }

    case .automatic:
      if indexPath.row == 1 {
        return switchCell(title: "Mirror While Paused", isOn: controller.mirrorsWhilePaused(game: gameID)) { [weak self] isOn in
          guard let self else { return }
          self.controller.setMirrorsWhilePaused(isOn, game: self.gameID)
        }
      }
      return switchCell(title: "Automatic", isOn: controller.isAutomatic(game: gameID)) { [weak self] isOn in
        guard let self else { return }
        self.controller.setAutomatic(isOn, game: self.gameID)
        self.tableView.reloadData()
      }

    case .layout:
      let item = layouts[indexPath.row]
      return checkmarkCell(title: item.title, subtitle: item.subtitle,
                           checked: controller.layout(game: gameID) == item.value)

    case .innerArrangement:
      let item = arrangements[indexPath.row]
      return checkmarkCell(title: item.title, subtitle: item.subtitle,
                           checked: controller.innerArrangement(game: gameID) == item.value)

    case .outerPicture, .innerPicture:
      let outer = section == .outerPicture
      if outer && indexPath.row == linkRow {
        return switchCell(title: "Same for Both Screens", isOn: linked) { [weak self] isOn in
          guard let self else { return }
          self.controller.setPictureLinked(isOn, game: self.gameID)
          self.tableView.reloadData()
        }
      }
      if indexPath.row == stretchRow {
        return sliderCell(value: controller.stretchAmount(outer: outer, game: gameID)) { [weak self] value in
          guard let self else { return }
          self.controller.setStretchAmount(value, outer: outer, game: self.gameID)
        }
      }
      let item = scalings[indexPath.row]
      return checkmarkCell(title: item.title, subtitle: item.subtitle,
                           checked: controller.scaling(outer: outer, game: gameID) == item.value)

    case .options:
      return switchCell(title: "Swap Screens", isOn: controller.swapHalves(game: gameID)) { [weak self] isOn in
        guard let self else { return }
        self.controller.setSwapHalves(isOn, game: self.gameID)
      }

    case .games:
      let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
      var content = cell.defaultContentConfiguration()
      if indexPath.row < savedGames.count {
        let game = savedGames[indexPath.row]
        content.text = game.title
        content.secondaryText = summary(game: game.id)
        content.secondaryTextProperties.color = .secondaryLabel
        cell.accessoryType = .disclosureIndicator
      } else {
        content.text = "Add Game…"
        content.textProperties.color = tintColorForAddRow
      }
      cell.contentConfiguration = content
      return cell

    case .gameActions:
      let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
      var content = cell.defaultContentConfiguration()
      content.text = "Use These for All Games"
      content.textProperties.color = tintColorForAddRow
      cell.contentConfiguration = content
      return cell
    }
  }

  private var tintColorForAddRow: UIColor { view.tintColor ?? .systemBlue }

  /// For example "Split: Top & Bottom · Outer: Zoom to Fill · Inner: Fit, 40% stretch".
  private func summary(game: String) -> String {
    let layout = controller.layout(game: game)
    var layoutName = layouts.first { $0.value == layout }?.title ?? "Mirror"
    if controller.isAutomatic(game: game) {
      layoutName = "Automatic"
    }
    let outer = OuterDisplayMirrorController.describe(scaling: controller.scaling(outer: true, game: game),
                                                      stretch: controller.stretchAmount(outer: true, game: game))
    if layout == .mirror && !controller.isAutomatic(game: game) {
      return "\(layoutName) · Outer: \(outer)"
    }
    let name = OuterDisplayMirrorController.isGrid(layout) && controller.innerArrangement(game: game) == .stacked
      ? "\(layoutName) (Top & Bottom)" : layoutName
    let inner = OuterDisplayMirrorController.describe(scaling: controller.scaling(outer: false, game: game),
                                                      stretch: controller.stretchAmount(outer: false, game: game))
    if controller.isPictureLinked(game: game) {
      return "\(name) · Both: \(outer)"
    }
    return "\(name) · Outer: \(outer) · Inner: \(inner)"
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)

    let section = sectionAt(indexPath.section)
    switch section {
    case .layout:
      controller.setLayout(layouts[indexPath.row].value, game: gameID)
    case .innerArrangement:
      controller.setInnerArrangement(arrangements[indexPath.row].value, game: gameID)
    case .outerPicture, .innerPicture:
      guard indexPath.row < scalings.count else { return }
      controller.setScaling(scalings[indexPath.row].value, outer: section == .outerPicture, game: gameID)
    case .games:
      if indexPath.row < savedGames.count {
        let game = savedGames[indexPath.row]
        navigationController?.pushViewController(
          OuterDisplaySettingsViewController(gameID: game.id, gameTitle: game.title), animated: true)
      } else {
        navigationController?.pushViewController(OuterDisplayGamePickerViewController(), animated: true)
      }
      return
    case .gameActions:
      controller.saveProfileAsDefaults(game: gameID)
      let alert = UIAlertController(title: "Saved as Defaults",
                                    message: "Games without their own settings now use these.",
                                    preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default))
      present(alert, animated: true)
      return
    default:
      return
    }
    tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none)
  }

  override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
    switch sectionAt(indexPath.section) {
    case .layout, .innerArrangement, .games, .gameActions: return true
    case .outerPicture, .innerPicture: return indexPath.row < scalings.count
    default: return false
    }
  }

  // Swipe a game in the list to remove its settings.
  override func tableView(_ tableView: UITableView,
                          trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    guard sectionAt(indexPath.section) == .games, indexPath.row < savedGames.count else { return nil }
    let game = savedGames[indexPath.row]
    let reset = UIContextualAction(style: .destructive, title: "Use Defaults") { [weak self] _, _, done in
      guard let self else { return done(false) }
      self.controller.resetProfile(game: game.id)
      self.savedGames = self.controller.savedGames()
      tableView.deleteRows(at: [indexPath], with: .automatic)
      done(true)
    }
    return UISwipeActionsConfiguration(actions: [reset])
  }

  // MARK: - Cells

  private func checkmarkCell(title: String, subtitle: String, checked: Bool) -> UITableViewCell {
    let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
    var content = cell.defaultContentConfiguration()
    content.text = title
    content.secondaryText = subtitle
    content.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = content
    cell.accessoryType = checked ? .checkmark : .none
    return cell
  }

  private func switchCell(title: String, isOn: Bool, onChange: @escaping (Bool) -> Void) -> UITableViewCell {
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
    var content = cell.defaultContentConfiguration()
    content.text = title
    cell.contentConfiguration = content
    cell.selectionStyle = .none

    let toggle = UISwitch()
    toggle.isOn = isOn
    toggle.addAction(UIAction { action in
      onChange((action.sender as? UISwitch)?.isOn ?? false)
    }, for: .valueChanged)
    cell.accessoryView = toggle
    return cell
  }

  /// "Stretch" label, a 0–100% slider, and the current percentage. Updates live while dragging.
  private func sliderCell(value: Float, onChange: @escaping (Float) -> Void) -> UITableViewCell {
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
    cell.selectionStyle = .none

    let label = UILabel()
    label.text = "Stretch"
    label.setContentHuggingPriority(.required, for: .horizontal)

    let percent = UILabel()
    percent.font = .monospacedDigitSystemFont(ofSize: UIFont.labelFontSize, weight: .regular)
    percent.textColor = .secondaryLabel
    percent.textAlignment = .right
    percent.text = "\(Int((value * 100).rounded()))%"
    percent.widthAnchor.constraint(equalToConstant: 52).isActive = true

    let slider = UISlider()
    slider.minimumValue = 0
    slider.maximumValue = 1
    slider.value = value
    slider.addAction(UIAction { action in
      guard let slider = action.sender as? UISlider else { return }
      // Snap to 5% steps so values are easy to repeat.
      let snapped = (slider.value * 20).rounded() / 20
      percent.text = "\(Int((snapped * 100).rounded()))%"
      onChange(snapped)
    }, for: .valueChanged)

    let stack = UIStackView(arrangedSubviews: [label, slider, percent])
    stack.axis = .horizontal
    stack.spacing = 12
    stack.alignment = .center
    stack.translatesAutoresizingMaskIntoConstraints = false
    cell.contentView.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
      stack.topAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.topAnchor),
      stack.bottomAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.bottomAnchor),
    ])
    return cell
  }
}

/// Settings → Split-Duo → Add Game…: the library's games that don't have their own settings yet.
/// Picking one opens its settings page; it shows the defaults until something is changed.
final class OuterDisplayGamePickerViewController: UITableViewController {
  private var games: [(id: String, title: String)] = []

  init() {
    super.init(style: .insetGrouped)
    title = "Add Game"
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    title = "Add Game"
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    let controller = OuterDisplayMirrorController.shared
    games = OuterDisplayGameLibrary.games().compactMap { entry in
      guard let id = entry["id"], let title = entry["title"], !controller.hasProfile(game: id) else { return nil }
      return (id: id, title: title)
    }
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    max(games.count, 1)
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
    var content = cell.defaultContentConfiguration()
    if games.isEmpty {
      content.text = "No other games in your library"
      content.textProperties.color = .secondaryLabel
      cell.selectionStyle = .none
    } else {
      content.text = games[indexPath.row].title
      content.secondaryText = games[indexPath.row].id
      content.secondaryTextProperties.color = .secondaryLabel
      cell.accessoryType = .disclosureIndicator
    }
    cell.contentConfiguration = content
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    guard !games.isEmpty else { return }
    let game = games[indexPath.row]
    let controller = OuterDisplayMirrorController.shared
    controller.rememberTitle(game.title, game: game.id)

    // Replace this picker with the game's page, so Back returns to Split-Duo.
    let page = OuterDisplaySettingsViewController(gameID: game.id, gameTitle: game.title)
    guard var stack = navigationController?.viewControllers else { return }
    stack[stack.count - 1] = page
    navigationController?.setViewControllers(stack, animated: true)
  }
}

#endif
