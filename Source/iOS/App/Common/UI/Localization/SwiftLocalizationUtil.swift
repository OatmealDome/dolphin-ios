// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import Foundation

func DOLCoreLocalizedString(_ localizable: String) -> String {
  return NSLocalizedString(localizable, tableName: "Core", bundle: Bundle.main, value: localizable, comment: "")
}
