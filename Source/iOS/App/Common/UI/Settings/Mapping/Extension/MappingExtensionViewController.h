// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

namespace ControllerEmu {
class Attachments;
}

@protocol MappingExtensionViewControllerDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface MappingExtensionViewController : UITableViewController

@property (weak, nonatomic, nullable) id<MappingExtensionViewControllerDelegate> delegate;

@property (nonatomic) ControllerEmu::Attachments* attachments;

@end

NS_ASSUME_NONNULL_END
