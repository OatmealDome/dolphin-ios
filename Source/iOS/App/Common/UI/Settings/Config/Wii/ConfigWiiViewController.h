// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

#import "DOLSwitch.h"

NS_ASSUME_NONNULL_BEGIN

@interface ConfigWiiViewController : UITableViewController

@property (weak, nonatomic) IBOutlet DOLUIKitSwitch* palSwitch;
@property (weak, nonatomic) IBOutlet DOLUIKitSwitch* screenSaverSwitch;
@property (weak, nonatomic) IBOutlet DOLUIKitSwitch* usbKeyboardSwitch;
@property (weak, nonatomic) IBOutlet UILabel* aspectRatioLabel;
@property (weak, nonatomic) IBOutlet UILabel* languageLabel;
@property (weak, nonatomic) IBOutlet UILabel* audioLabel;
@property (weak, nonatomic) IBOutlet DOLUIKitSwitch* sdInsertedSwitch;
@property (weak, nonatomic) IBOutlet DOLUIKitSwitch* sdWritesSwitch;
@property (weak, nonatomic) IBOutlet DOLUIKitSwitch* sdSyncSwitch;
@property (weak, nonatomic) IBOutlet UILabel* sensorBarLabel;
@property (weak, nonatomic) IBOutlet UISlider* irSlider;
@property (weak, nonatomic) IBOutlet UISlider* speakerVolumeSlider;
@property (weak, nonatomic) IBOutlet DOLUIKitSwitch* rumbleSwitch;

@end

NS_ASSUME_NONNULL_END
