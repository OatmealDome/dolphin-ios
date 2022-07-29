// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

#import "MappingDeviceViewControllerDelegate.h"
#import "MappingExtensionViewControllerDelegate.h"
#import "MappingGroupEditViewControllerDelegate.h"
#import "MappingLoadProfileViewControllerDelegate.h"

typedef NS_ENUM(NSUInteger, DOLMappingType) {
  DOLMappingTypePad,
  DOLMappingTypeWiimote
};

NS_ASSUME_NONNULL_BEGIN

@interface MappingRootViewController : UITableViewController <MappingDeviceViewControllerDelegate, MappingExtensionViewControllerDelegate, MappingGroupEditViewControllerDelegate, MappingLoadProfileViewControllerDelegate>

@property (nonatomic) DOLMappingType mappingType;
@property (nonatomic) int mappingPort;

@property (weak, nonatomic) IBOutlet UIBarButtonItem* profilesButton;

@end

NS_ASSUME_NONNULL_END
