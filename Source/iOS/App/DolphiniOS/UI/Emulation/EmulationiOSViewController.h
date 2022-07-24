// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "EmulationViewController.h"

#import "Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface EmulationiOSViewController : EmulationViewController

@property (weak, nonatomic) IBOutlet NSLayoutConstraint* metalHalfConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *metalBottomConstraint;

@property (strong, nonatomic) IBOutletCollection(TCView) NSArray* touchPads;

@end

NS_ASSUME_NONNULL_END
