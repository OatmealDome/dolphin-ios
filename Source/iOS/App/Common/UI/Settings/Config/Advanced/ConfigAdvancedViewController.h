// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

#import "DOLSwitch.h"

NS_ASSUME_NONNULL_BEGIN

@interface ConfigAdvancedViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UILabel* engineLabel;
@property (weak, nonatomic) IBOutlet DOLSwitch* mmuSwitch;
@property (weak, nonatomic) IBOutlet DOLSwitch* panicPauseSwitch;
@property (weak, nonatomic) IBOutlet DOLSwitch* writeBackCacheSwitch;
@property (weak, nonatomic) IBOutlet DOLSwitch* cpuClockSwitch;
@property (weak, nonatomic) IBOutlet UISlider* cpuClockSlider;
@property (weak, nonatomic) IBOutlet UILabel* cpuClockLabel;
@property (weak, nonatomic) IBOutlet DOLSwitch* vbiClockSwitch;
@property (weak, nonatomic) IBOutlet UISlider* vbiClockSlider;
@property (weak, nonatomic) IBOutlet UILabel* vbiClockLabel;
@property (weak, nonatomic) IBOutlet DOLSwitch* memorySwitch;
@property (weak, nonatomic) IBOutlet UISlider* memOneSlider;
@property (weak, nonatomic) IBOutlet UILabel* memOneLabel;
@property (weak, nonatomic) IBOutlet UISlider* memTwoSlider;
@property (weak, nonatomic) IBOutlet UILabel* memTwoLabel;
@property (weak, nonatomic) IBOutlet DOLSwitch* rtcSwitch;
@property (weak, nonatomic) IBOutlet UIDatePicker* rtcPicker;

@end

NS_ASSUME_NONNULL_END
