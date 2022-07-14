// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

#import "DOLSwitch.h"

NS_ASSUME_NONNULL_BEGIN

@interface ConfigInterfaceViewController : UITableViewController

@property (weak, nonatomic) IBOutlet DOLUIKitSwitch* namesSwitch;
@property (weak, nonatomic) IBOutlet DOLUIKitSwitch* coversSwitch;
@property (weak, nonatomic) IBOutlet DOLUIKitSwitch* panicHandlersSwitch;
@property (weak, nonatomic) IBOutlet DOLUIKitSwitch* stopSwitch;
@property (weak, nonatomic) IBOutlet DOLUIKitSwitch* osdMessagesSwitch;

@end

NS_ASSUME_NONNULL_END
