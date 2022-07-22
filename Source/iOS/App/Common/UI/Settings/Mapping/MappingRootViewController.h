// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

#import "MappingExtensionViewControllerDelegate.h"
#import "MappingGroupEditViewControllerDelegate.h"

typedef NS_ENUM(NSUInteger, DOLMappingType) {
  DOLMappingTypePad,
  DOLMappingTypeWiimote
};

NS_ASSUME_NONNULL_BEGIN

@interface MappingRootViewController : UITableViewController <MappingExtensionViewControllerDelegate, MappingGroupEditViewControllerDelegate>

@property (nonatomic) DOLMappingType mappingType;
@property (nonatomic) int mappingPort;

@end

NS_ASSUME_NONNULL_END
