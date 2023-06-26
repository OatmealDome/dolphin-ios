// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

namespace Gecko {
class GeckoCode;
}

@protocol GeckoCodeEditViewControllerDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface GeckoCodeEditViewController : UITableViewController

@property (weak, nonatomic, nullable) id<GeckoCodeEditViewControllerDelegate> delegate;

@property (nonatomic) Gecko::GeckoCode* code;

@property (weak, nonatomic) IBOutlet UITextField* nameField;
@property (weak, nonatomic) IBOutlet UITextField* creatorField;
@property (weak, nonatomic) IBOutlet UITextView* codeView;
@property (weak, nonatomic) IBOutlet UITextView* notesView;

@end

NS_ASSUME_NONNULL_END
