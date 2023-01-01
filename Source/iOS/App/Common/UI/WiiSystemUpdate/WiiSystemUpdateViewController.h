// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WiiSystemUpdateViewController : UIViewController

@property (nonatomic) bool isOnlineUpdate;
@property (nonatomic) NSString* updateSource;

@property (weak, nonatomic) IBOutlet UIProgressView* progressBar;
@property (weak, nonatomic) IBOutlet UILabel* statusLabel;
@property (weak, nonatomic) IBOutlet UIButton* cancelButton;

@end

NS_ASSUME_NONNULL_END
