// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

namespace ControllerEmu {
class Attachments;
}

NS_ASSUME_NONNULL_BEGIN

@interface MappingExtensionViewController : UITableViewController

@property (nonatomic) ControllerEmu::Attachments* attachments;

@end

NS_ASSUME_NONNULL_END
