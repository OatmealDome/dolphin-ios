// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

namespace Config {
template <typename T>
class Info;
}

@interface GraphicsChoiceCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel* choiceNameLabel;
@property (weak, nonatomic) IBOutlet UILabel* choiceSettingLabel;

- (void)updateWithConfig:(const Config::Info<int>&) setting;

@end

NS_ASSUME_NONNULL_END
