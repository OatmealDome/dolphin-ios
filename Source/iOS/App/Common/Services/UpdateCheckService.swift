// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import UIKit

class UpdateCheckService : UIResponder, UIApplicationDelegate {
  func createUpdateRequiredViewController() -> UIViewController {
    return UpdateRequiredNoticeViewController(nibName: "UpdateRequiredNotice", bundle: nil)
  }
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    let noticeManager = BootNoticeManager.shared()
    
    let updateRequired = UserDefaults.standard.bool(forKey: "update_required")
    if (updateRequired) {
      noticeManager.enqueueNoExitViewController(createUpdateRequiredViewController())
      
      return true
    }
    
#if !DEBUG
    let currentVersion = VersionManager.shared().userFacingVersion
    
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
      
      let updateRequiredBuilds = json["kbs"] as! Array<String>
      
      if (updateRequiredBuilds.contains(currentVersion)) {
        UserDefaults.standard.set(true, forKey: "update_required")
        
        DispatchQueue.main.async {
          noticeManager.enqueueNoExitViewController(self.createUpdateRequiredViewController())
          noticeManager.presentToSceneIfNecessary()
        }
        
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
