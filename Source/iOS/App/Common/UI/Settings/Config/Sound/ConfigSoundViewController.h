// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

#import "DOLSwitch.h"

NS_ASSUME_NONNULL_BEGIN

@interface ConfigSoundViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UILabel* backendLabel;
@property (weak, nonatomic) IBOutlet UISlider* volumeSlider;
@property (weak, nonatomic) IBOutlet UILabel* volumeLabel;
@property (weak, nonatomic) IBOutlet UISlider* bufferSizeSlider;
@property (weak, nonatomic) IBOutlet UILabel* bufferSizeLabel;
@property (weak, nonatomic) IBOutlet DOLUIKitSwitch* fillGapsSwitch;
@property (weak, nonatomic) IBOutlet DOLUIKitSwitch* muteSpeedLimitSwitch;
@property (weak, nonatomic) IBOutlet DOLUIKitSwitch* muteModeSwitch;

@end

NS_ASSUME_NONNULL_END
