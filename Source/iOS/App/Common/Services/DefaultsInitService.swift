// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import UIKit

class DefaultsInitService : UIResponder, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    // Create the Documents folder in case it doesn't exist
    let userFolder: String = UserFolderUtil.getUserFolder()
    try! FileManager.default.createDirectory(atPath: userFolder, withIntermediateDirectories: true, attributes: nil)
    
    let softwareFolder: String = UserFolderUtil.getSoftwareFolder()
    try! FileManager.default.createDirectory(atPath: softwareFolder, withIntermediateDirectories: true, attributes: nil)
    
    // Set NSURLIsExcludedFromBackupKey on the folder and all its subcontents
    
    var softwareResourceValues = URLResourceValues()
    softwareResourceValues.isExcludedFromBackup = true
    
    var softwareFolderUrl: URL = URL(fileURLWithPath: softwareFolder)
    try! softwareFolderUrl.setResourceValues(softwareResourceValues)
    
    return true
  }
}
