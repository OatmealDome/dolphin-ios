// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

namespace ActionReplay {
class ARCode;
}

@protocol ActionReplayCodeEditViewControllerDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface ActionReplayCodeEditViewController : UITableViewController

@property (weak, nonatomic, nullable) id<ActionReplayCodeEditViewControllerDelegate> delegate;

@property (nonatomic) ActionReplay::ARCode* code;

@property (weak, nonatomic) IBOutlet UITextField* nameField;
@property (weak, nonatomic) IBOutlet UITextView* codeView;

@end

NS_ASSUME_NONNULL_END
