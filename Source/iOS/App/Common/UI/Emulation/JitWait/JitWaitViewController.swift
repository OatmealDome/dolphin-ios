// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import UIKit

class JitWaitViewController: UIViewController {
  @objc weak var delegate: JitWaitViewControllerDelegate?
  @IBOutlet var stikJITActivityIndicator: UIActivityIndicatorView!
  @IBOutlet var stikJITStatusView: UIStackView!

  var timer: Timer?
  var isShowingError: Bool = false

  override func viewDidLoad() {
    super.viewDidLoad()

    self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(checkJit), userInfo: nil, repeats: true)

    switch StikJITManager.shared.jitLaunchMode {
    case .waitForDebugger:
      break
    case .externalStikDebug:
      JitManager.shared().acquireJitByStikDebugURLScheme()
    case .builtInStikJIT:
      guard #available(iOS 17.4, *),
            !StikJITManager.shared.isRunningInLiveContainer,
            StikJITManager.shared.hasPairingFile else {
        StikJITManager.shared.jitLaunchMode = .waitForDebugger
        return
      }
      JitManager.shared().acquireJitByStikJIT()
    }

    self.updateStikJITIndicator()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    self.updateStikJITIndicator()
    self.showAcquisitionErrorIfNecessary()
  }
  
  @objc func checkJit() {
    self.updateStikJITIndicator()

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

  func updateStikJITIndicator() {
    let isRunning = JitManager.shared().isStikJITRunning
    self.stikJITStatusView.isHidden = !isRunning

    if isRunning {
      self.stikJITActivityIndicator.startAnimating()
    } else {
      self.stikJITActivityIndicator.stopAnimating()
    }
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
