// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DOLUIKitSwitch : UISwitch

- (void)addValueChangedTarget:(nullable id)target action:(SEL)action;

@end

NS_ASSUME_NONNULL_END
