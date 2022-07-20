// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

#import "ControllersRootPortCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface ControllersRootViewController : UITableViewController

@property (strong, nonatomic) IBOutletCollection(ControllersRootPortCell) NSArray* gamecubeCells;
@property (strong, nonatomic) IBOutletCollection(ControllersRootPortCell) NSArray* wiiCells;

@end

NS_ASSUME_NONNULL_END
