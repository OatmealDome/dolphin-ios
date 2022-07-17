// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

#import "DOLSwitch.h"

NS_ASSUME_NONNULL_BEGIN

@interface ConfigInterfaceViewController : UITableViewController

@property (weak, nonatomic) IBOutlet DOLSwitch* namesSwitch;
@property (weak, nonatomic) IBOutlet DOLSwitch* coversSwitch;
@property (weak, nonatomic) IBOutlet DOLSwitch* panicHandlersSwitch;
@property (weak, nonatomic) IBOutlet DOLSwitch* stopSwitch;
@property (weak, nonatomic) IBOutlet DOLSwitch* osdMessagesSwitch;

@end

NS_ASSUME_NONNULL_END
