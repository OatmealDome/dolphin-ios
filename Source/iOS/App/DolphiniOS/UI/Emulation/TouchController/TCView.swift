// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import Foundation
import UIKit

@objc class TCView: UIView
{
  var real_view: UIView?
  
  private var _port: Int = 0
  @objc var port: Int
  {
    get
    {
      return _port
    }
    set
    {
      _port = newValue
      
      SetPort(newValue, view: real_view!)
    }
  }
  
  required init?(coder: NSCoder)
  {
    super.init(coder: coder)
    
    // Load ourselves from the nib
    let name = String(describing: type(of: self))
    let view = Bundle(for: type(of: self)).loadNibNamed(name, owner: self, options: nil)![0] as! UIView
    view.frame = self.bounds
    self.addSubview(view)
    
    real_view = view;
  }
  
  func SetPort(_ port: Int, view: UIView)
  {
    for subview in view.subviews
    {
      if (subview is TCButton)
      {
        (subview as! TCButton).port = port
      }
      else if (subview is TCJoystick)
      {
        (subview as! TCJoystick).port = port
      }
      else if (subview is TCDirectionalPad)
      {
        (subview as! TCDirectionalPad).port = port
      }
      else
      {
        SetPort(port, view: subview)
      }
    }
  }
  
}
