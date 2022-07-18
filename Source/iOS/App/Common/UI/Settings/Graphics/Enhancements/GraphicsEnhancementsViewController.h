// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "GraphicsTabViewController.h"

#import "GraphicsBoolCell.h"
#import "GraphicsChoiceCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface GraphicsEnhancementsViewController : GraphicsTabViewController

@property (weak, nonatomic) IBOutlet GraphicsChoiceCell* resolutionCell;
@property (weak, nonatomic) IBOutlet GraphicsChoiceCell* filteringCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* scaledEfbCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* textureFilteringCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* fogCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* filterCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* lightingCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* widescreenHackCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* colorCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* mipmapCell;

@end

NS_ASSUME_NONNULL_END
