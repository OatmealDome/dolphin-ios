// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import Foundation

// based off ButtonManager::ButtonType
@objc
enum TCButtonType: Int
{
  // GameCube
  case gcButtonA = 0
  case gcButtonB = 1
  case gcButtonStart = 2
  case gcButtonX = 3
  case gcButtonY = 4
  case gcButtonZ = 5
  case gcButtonUp = 6
  case gcButtonDown = 7
  case gcButtonLeft = 8
  case gcButtonRight = 9
  case gcStickMain = 10
  case gcStickC = 15
  case gcTriggerL = 20
  case gcTriggerR = 21
  // Wiimote
  case wiiButtonA = 100
  case wiiButtonB = 101
  case wiiButtonMinus = 102
  case wiiButtonPlus = 103
  case wiiButtonHome = 104
  case wiiButtonOne = 105
  case wiiButtonTwo = 106
  case wiiPadUp = 107
  case wiiPadDown = 108
  case wiiPadLeft = 109
  case wiiPadRight = 110
  case wiiInfrared = 111
  case wiiInfraredUp = 112
  case wiiInfraredDown = 113
  case wiiInfraredLeft = 114
  case wiiInfraredRight = 115
  case wiiInfraredForward = 116
  case wiiInfraredBackward = 117
  case wiiInfraredHide = 118
  case wiiSwing = 119
  case wiiSwingUp = 120
  case wiiSwingDown = 121
  case wiiSwingLeft = 122
  case wiiSwingRight = 123
  case wiiSwingForward = 124
  case wiiSwingBackward = 125
  case wiiTilt = 126
  case wiiTiltForward = 127
  case wiiTiltBackward = 128
  case wiiTiltLeft = 129
  case wiiTiltRight = 130
  case wiiTiltModifier = 131
  case wiiShakeX = 132
  case wiiShakeY = 133
  case wiiShakeZ = 134
  // Nunchuk
  case nunchukButtonC = 200
  case nunchukButtonZ = 201
  case nunchukStick = 202
  case nunchukSwing = 207
  case nunchukSwingUp = 208
  case nunchukSwingDown = 209
  case nunchukSwingLeft = 210
  case nunchukSwingRight = 211
  case nunchukSwingForward = 212
  case nunchukSwingBackward = 213
  case nunchukTilt = 214
  case nunchukTiltForward = 215
  case nunchukTiltBackward = 216
  case nunchukTiltLeft = 217
  case nunchukTiltRight = 218
  case nunchukTiltModifier = 219
  case nunchukShakeX = 220
  case nunchukShakeY = 221
  case nunchukShakeZ = 222
  // Classic Controller
  case classicButtonA = 300
  case classicButtonB = 301
  case classicButtonX = 302
  case classicButtonY = 303
  case classicButtonMINUS = 304
  case classicButtonPLUS = 305
  case classicButtonHOME = 306
  case classicButtonZL = 307
  case classicButtonZR = 308
  case classicPadUp = 309
  case classicPadDown = 310
  case classicPadLeft = 311
  case classicPadRight = 312
  case classicStickLeft = 313
  case classicStickLeftUp = 314
  case classicStickLeftDown = 315
  case classicStickLeftLeft = 316
  case classicStickLeftRight = 317
  case classicStickRight = 318
  case classicStickRightUp = 319
  case classicStickRightDown = 320
  case classicStickRightLeft = 321
  case classicStickRightRight = 322
  case classicTriggerL = 323
  case classicTriggerR = 324
  // Wiimote IMU
  case wiiAccelLeft = 625
  case wiiAccelRight = 626
  case wiiAccelForward = 627
  case wiiAccelBackward = 628
  case wiiAccelUp = 629
  case wiiAccelDown = 630
  case wiiGyroPitchUp = 631
  case wiiGyroPitchDown = 632
  case wiiGyroRollLeft = 633
  case wiiGyroRollRight = 634
  case wiiGyroYawLeft = 635
  case wiiGyroYawRight = 636
  // Wiimote IMU IR
  case wiiInfraredRecenter = 800
  // Nunchuk IMU
  case nunchukAccelLeft = 900
  case nunchukAccelRight = 901
  case nunchukAccelForward = 902
  case nunchukAccelBackward = 903
  case nunchukAccelUp = 904
  case nunchukAccelDown = 905
  // TODO: Guitar, Drums, Turntable, Rumble
  
  func getImageName() -> String
  {
    switch self
    {
    case .gcButtonA:
      return "gcpad_a"
    case .gcButtonB:
      return "gcpad_b"
    case .gcButtonStart:
      return "gcpad_start"
    case .gcButtonX:
      return "gcpad_x"
    case .gcButtonY:
      return "gcpad_y"
    case .gcButtonZ:
      return "gcpad_z"
    case .gcButtonUp, .gcButtonDown, .gcButtonLeft, .gcButtonRight, .wiiPadUp, .wiiPadDown,
         .wiiPadLeft, .wiiPadRight, .classicPadUp, .classicPadDown, .classicPadLeft, .classicPadRight:
      return "gcwii_dpad"
    case .gcStickMain, .wiiInfrared, .nunchukStick, .classicStickLeft, .classicStickRight:
      return "gcwii_joystick"
    case .gcStickC:
      return "gcpad_c"
    case .gcTriggerL:
      return "gcpad_l"
    case .gcTriggerR:
      return "gcpad_r"
    case .wiiButtonA:
      return "wiimote_a"
    case .wiiButtonB:
      return "wiimote_b"
    case .wiiButtonMinus, .classicButtonMINUS:
      return "wiimote_minus"
    case .wiiButtonPlus, .classicButtonPLUS:
      return "wiimote_plus"
    case .wiiButtonHome, .classicButtonHOME:
      return "wiimote_home"
    case .wiiButtonOne:
      return "wiimote_one"
    case .wiiButtonTwo:
      return "wiimote_two"
    case .nunchukButtonC:
      return "nunchuk_c"
    case .nunchukButtonZ:
      return "nunchuk_z"
    case .classicButtonA:
      return "classic_a"
    case .classicButtonB:
      return "classic_b"
    case .classicButtonX:
      return "classic_x"
    case .classicButtonY:
      return "classic_y"
    case .classicButtonZL:
      return "classic_zl"
    case .classicButtonZR:
      return "classic_zr"
    case .classicTriggerL:
      return "classic_l"
    case .classicTriggerR:
      return "classic_r"
    default:
      return "gcpad_a"
    }
  }
  
  func getButtonScale() -> CGFloat
  {
    switch self
    {
    case .gcButtonA, .gcButtonZ, .gcTriggerL, .gcTriggerR, .wiiButtonB, .nunchukButtonZ, .classicButtonZL, .classicButtonZR, .classicTriggerL, .classicTriggerR:
      return 0.6
    case .gcButtonB, .gcButtonStart, .wiiButtonOne, .wiiButtonTwo, .wiiButtonA, .classicButtonA, .classicButtonB, .classicButtonX, .classicButtonY:
      return 0.33
    case .gcButtonX, .gcButtonY:
      return 0.5
    case .wiiButtonPlus, .wiiButtonMinus, .classicButtonMINUS, .classicButtonPLUS:
      return 0.2
    case .wiiButtonHome, .classicButtonHOME:
      return 0.25
    case .nunchukButtonC:
      return 0.4
    default:
      return 1.0
    }
  }
}
