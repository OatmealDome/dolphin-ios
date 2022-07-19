// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

#import "ControllerPortCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface ControllersRootViewController : UITableViewController

@property (strong, nonatomic) IBOutletCollection(ControllerPortCell) NSArray<ControllerPortCell*>* gamecubeCells;
@property (strong, nonatomic) IBOutletCollection(ControllerPortCell) NSArray<ControllerPortCell*>* wiiCells;

@end

NS_ASSUME_NONNULL_END
