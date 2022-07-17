// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GraphicsTabViewController : UITableViewController

- (void)showHelpWithLocalizable:(NSString*)localizable;
- (void)showHelpWithMessage:(NSString*)message;

@end

NS_ASSUME_NONNULL_END
