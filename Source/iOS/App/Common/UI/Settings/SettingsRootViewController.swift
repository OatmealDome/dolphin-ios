// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import Foundation
import UIKit

class SettingsRootViewController : UITableViewController {
  @IBOutlet weak var versionLabel: UILabel!
  @IBOutlet weak var coreVersionLabel: UILabel!
  
  override func viewDidLoad() {
    let versionManager = VersionManager.shared()
    
    versionLabel.text = versionManager.userFacingVersion
    coreVersionLabel.text = versionManager.coreVersion
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    
    if (indexPath.section == 0 && indexPath.row == 3) {
      UIApplication.shared.open(URL(string: "https://oatmealdome.me/dolphinios/")!)
    }
  }
}
