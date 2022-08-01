// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import UIKit

class JitWaitViewController: UIViewController {
  @objc weak var delegate: JitWaitViewControllerDelegate?
  
  var timer: Timer?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(checkJit), userInfo: nil, repeats: true)
  }
  
  @objc func checkJit() {
    let manager = JitManager.shared()
    
    manager.recheckIfJitIsAcquired()
    
    if (manager.acquiredJit) {
      self.timer?.invalidate()
      self.delegate?.didFinishJitScreen(result: true, sender: self)
    }
  }
  
  @IBAction func helpPressed(_ sender: Any) {
    let url = URL.init(string: "https://dolphinios.oatmealdome.me/jit-help")
    UIApplication.shared.open(url!, options: [:], completionHandler: nil)
  }
  
  @IBAction func cancelPressed(_ sender: Any) {
    self.timer?.invalidate()
    self.delegate?.didFinishJitScreen(result: false, sender: self)
  }
}
