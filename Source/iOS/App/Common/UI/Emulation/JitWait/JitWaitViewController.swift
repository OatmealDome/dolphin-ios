// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import UIKit

class JitWaitViewController: UIViewController {
  @objc weak var delegate: JitWaitViewControllerDelegate?
  @IBOutlet var stikJITButton: UIButton!

  var timer: Timer?
  var isShowingError: Bool = false

  override func viewDidLoad() {
    super.viewDidLoad()

    self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(checkJit), userInfo: nil, repeats: true)

    if #available(iOS 17.4, *) {
      let stikJITReady = StikJITManager.shared.selfEnableJitEnabled && StikJITManager.shared.hasPairingFile
      stikJITButton.isHidden = !stikJITReady
    }

    JitManager.shared().acquireJitByAltServer()
    JitManager.shared().acquireJitByJitStreamer()
    JitManager.shared().acquireJitByStikDebugURLScheme()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    self.showAcquisitionErrorIfNecessary()
  }
  
  @objc func checkJit() {
    if (self.isShowingError) {
      return
    }
    
    let manager = JitManager.shared()
    
    manager.recheckIfJitIsAcquired()
    
    if (manager.acquiredJit) {
      self.timer?.invalidate()
      self.delegate?.didFinishJitScreen(result: .jitAcquired, sender: self)
      
      return
    }
    
    self.showAcquisitionErrorIfNecessary()
  }
  
  func showAcquisitionErrorIfNecessary() {
    let manager = JitManager.shared()
    
    if let error = manager.acquisitionError {
      manager.acquisitionError = nil
      self.isShowingError = true
      
      let alertController = UIAlertController(title: DOLCoreLocalizedString("Error"), message: error, preferredStyle: .alert)
      alertController.addAction(UIAlertAction(title: DOLCoreLocalizedString("OK"), style: .default, handler: {_ in
        self.isShowingError = false
      }))
      
      self.present(alertController, animated: true, completion: nil)
    }
  }
  
  @IBAction func stikJITPressed(_ sender: Any) {
    let alertController = UIAlertController(
      title: "Before Continuing",
      message: "If you have access to a nearby Wi-Fi network, connect to it now, connect to LocalDevVPN, then return here and continue. If you don't have access to a Wi-Fi network, make sure Cellular Data is enabled, connect to LocalDevVPN, then enable Airplane Mode, return here, and continue.",
      preferredStyle: .alert)

    alertController.addAction(UIAlertAction(title: DOLCoreLocalizedString("Cancel"), style: .cancel, handler: nil))
    alertController.addAction(UIAlertAction(title: "Continue", style: .default, handler: { [weak self] _ in
      self?.startStikJITWithDDICheck()
    }))

    self.present(alertController, animated: true, completion: nil)
  }

  private func startStikJITWithDDICheck() {
    guard #available(iOS 17.4, *) else {
      JitManager.shared().acquireJitByStikJIT()
      return
    }

    self.stikJITButton.isEnabled = false
    self.stikJITButton.setTitle("Checking Developer Disk Image...", for: .normal)

    DDIManager.shared.checkIsMounted { [weak self] mounted, _ in
      guard let self = self else { return }

      if mounted {
        self.finishDDIStepAndAcquireJit()
        return
      }

      DDIManager.shared.mountDDI(progress: { [weak self] fraction, status in
        self?.stikJITButton.setTitle("\(status) (\(Int(fraction * 100))%)", for: .normal)
      }, completion: { [weak self] success, error in
        guard let self = self else { return }

        if success {
          self.finishDDIStepAndAcquireJit()
          return
        }

        self.stikJITButton.isEnabled = true
        self.stikJITButton.setTitle("Enable JIT with StikJIT", for: .normal)

        let alertController = UIAlertController(title: DOLCoreLocalizedString("Error"), message: "Failed to mount Developer Disk Image: \(error ?? "Unknown error")", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: DOLCoreLocalizedString("OK"), style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
      })
    }
  }

  private func finishDDIStepAndAcquireJit() {
    self.stikJITButton.isEnabled = true
    self.stikJITButton.setTitle("Enable JIT with StikJIT", for: .normal)
    JitManager.shared().acquireJitByStikJIT()
  }

  @IBAction func helpPressed(_ sender: Any) {
    let url = URL.init(string: "https://dolphinios.oatmealdome.me/jit-help")
    UIApplication.shared.open(url!, options: [:], completionHandler: nil)
  }
  
  @IBAction func noJitPressed(_ sender: Any) {
    self.timer?.invalidate()
    self.delegate?.didFinishJitScreen(result: .noJitRequested, sender: self)
  }
  
  @IBAction func cancelPressed(_ sender: Any) {
    self.timer?.invalidate()
    self.delegate?.didFinishJitScreen(result: .cancel, sender: self)
  }
}
