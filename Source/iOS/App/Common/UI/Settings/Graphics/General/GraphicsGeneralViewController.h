// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "GraphicsTabViewController.h"

#import "GraphicsBoolCell.h"
#import "GraphicsChoiceCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface GraphicsGeneralViewController : GraphicsTabViewController

@property (weak, nonatomic) IBOutlet UILabel* backendLabel;
@property (weak, nonatomic) IBOutlet GraphicsChoiceCell* aspectRatioCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* vsyncCell;
@property (weak, nonatomic) IBOutlet GraphicsChoiceCell* shaderModeCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* shaderCompileCell;

@end

NS_ASSUME_NONNULL_END
