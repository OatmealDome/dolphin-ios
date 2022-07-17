// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "DOLUIKitSwitch.h"

@implementation DOLUIKitSwitch {
  BOOL _registeredValueChangedTarget;
}

- (void)addValueChangedTarget:(nullable id)target action:(SEL)action {
  if (_registeredValueChangedTarget) {
    return;
  }
  
  [self addTarget:target action:action forControlEvents:UIControlEventValueChanged];
  
  _registeredValueChangedTarget = true;
}

@end
