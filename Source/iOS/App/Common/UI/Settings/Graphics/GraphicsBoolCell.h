// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

#import "DOLSwitch.h"

namespace Config {
template <typename T>
class Info;
}

NS_ASSUME_NONNULL_BEGIN

@interface GraphicsBoolCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel* boolLabel;
@property (weak, nonatomic) IBOutlet DOLSwitch* boolSwitch;

- (void)updateWithConfig:(const Config::Info<bool>&) setting;
- (void)updateWithConfig:(const Config::Info<bool>&) setting shouldReverse:(bool)reverse;

@end

NS_ASSUME_NONNULL_END
