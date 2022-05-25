// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "DOLUIKitSwitch.h"

@implementation DOLUIKitSwitch

- (void)addValueChangedTarget:(nullable id)target action:(SEL)action {
  [self addTarget:target action:action forControlEvents:UIControlEventValueChanged];
}

@end
