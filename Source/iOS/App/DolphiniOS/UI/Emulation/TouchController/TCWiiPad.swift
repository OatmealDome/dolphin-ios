// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import Foundation
import UIKit

class TCWiiPad: TCView, UIGestureRecognizerDelegate {
  var touchPointerEnabled: Bool = true
  
  var gameCenterX: CGFloat = 0
  var gameCenterY: CGFloat = 0
  var gameWidthHalfInv: CGFloat = 0
  var gameHeightHalfInv: CGFloat = 0
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    
    // Register our "long press" gesture recognizer
    let pressHandler = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
    pressHandler.minimumPressDuration = 0
    pressHandler.numberOfTouchesRequired = 1
    pressHandler.cancelsTouchesInView = false
    pressHandler.delegate = self
    self.real_view!.addGestureRecognizer(pressHandler)
  }
  
  @objc func recalculatePointerValues(new_rect: CGRect, game_aspect: CGFloat) {
    gameCenterX = new_rect.midX
    gameCenterY = new_rect.midY

    var gameWidth = new_rect.width
    var gameHeight = new_rect.height

    // Adjusting for device's black bars.
    let surfaceAR = gameWidth / gameHeight
    let gameAR = game_aspect
    if (gameAR <= surfaceAR) {
        // Black bars on left/right
        gameWidth = gameHeight * gameAR
    } else {
        // Black bars on top/bottom
        gameHeight = gameWidth / gameAR
    }

    gameWidthHalfInv = 1 / (gameWidth * 0.5)
    gameHeightHalfInv = 1 / (gameHeight * 0.5)
  }
  
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    if (touch.view == self.real_view) {
      return true
    }
    
    return false
  }
  
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    if (otherGestureRecognizer is UIScreenEdgePanGestureRecognizer) {
      return true
    }
    
    return false
  }
  
  @objc func handleLongPress(gesture: UILongPressGestureRecognizer) {
    if (!self.touchPointerEnabled) {
      return
    }
    
    let point = gesture.location(in: self)
    
    var axises: (y: CGFloat, x: CGFloat) = (0, 0)
    
    axises.x = (point.x - gameCenterX) * gameWidthHalfInv
    axises.y = (point.y - gameCenterY) * gameHeightHalfInv
    
    let axisStartIdx = TCButtonType.wiiInfrared
    for (i, axis) in [axises.y, axises.y, axises.x, axises.x].enumerated() {
      TCManagerInterface.setAxisValueFor(axisStartIdx.rawValue + i + 1, controller: self.port, value: Float(axis))
    }
  }
  
  @objc func setTouchPointerEnabled(_ enabled: Bool) {
    self.touchPointerEnabled = enabled
  }
}
