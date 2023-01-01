// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import UIKit

class UpdateCheckService : UIResponder, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
#if !DEBUG
    let info = Bundle.main.infoDictionary!
    let currentVersion = String(format: "%@ (%@)", info["CFBundleShortVersionString"] as! String, info["CFBundleVersion"] as! String)
    
    let session = URLSession(configuration: URLSessionConfiguration.ephemeral)
    let updateUrl = URL(string: "https://dolphinios.oatmealdome.me/api/v2/update.json")!
    
    session.dataTask(with: updateUrl) { (data, response, error) in
      guard let unwrappedData = data else {
        return
      }
      
      let possibleJson = try? JSONSerialization.jsonObject(with: unwrappedData)
      
      guard let json = possibleJson as? NSDictionary else {
        return
      }
      
      var key: String
#if BETA
#if NONJAILBROKEN
      key = "public_beta_njb"
#else
      key = "public_beta"
#endif
#else
#if NONJAILBROKEN
      key = "public_njb"
#else
      key = "public"
#endif
#endif
      
      let versionInfo = json[key] as! Dictionary<AnyHashable, Any>
      let newVersion = versionInfo["version"] as! String
      
      if (newVersion != currentVersion) {
        DispatchQueue.main.async {
          let updateController = UpdateNoticeViewController(nibName: "UpdateNotice", bundle: nil)
          updateController.updateInfo = versionInfo
          
          let noticeManager = BootNoticeManager.shared()
          noticeManager.enqueue(updateController)
          noticeManager.presentToSceneIfNecessary()
        }
      }
    }.resume()
#endif
    
    return true
  }
}

