// Copyright 2024 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import UIKit

final class LowPowerModeWarningViewController: UIViewController {
  typealias EmulationShouldStartHandler = () -> Void

  @objc var emulationShouldStartHandler: EmulationShouldStartHandler?

  override func viewDidLoad() {
    super.viewDidLoad()

    LowPowerModeManager.shared().lowPowerModeDidChangeHandler = { [weak self] isLowPowerMode in
      self?.emulationShouldStartHandler?()
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    LowPowerModeManager.shared().lowPowerModeDidChangeHandler = nil
  }

  @IBAction func continueAnywayPressed(_ sender: Any) {
    emulationShouldStartHandler?()
  }

  @IBAction func disableLowPowerModePressed(_ sender: Any) {
    let url = URL.init(string: "prefs:root=BATTERY_USAGE") // todo: maybe change this one day if app is released on Apple AppStore
    UIApplication.shared.open(url!, options: [:], completionHandler: nil)
  }
}
