// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "GraphicsTabViewController.h"

#import "GraphicsBoolCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface GraphicsHacksViewController : GraphicsTabViewController

@property (weak, nonatomic) IBOutlet GraphicsBoolCell* skipEfbCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* efbToTextureCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* formatChangesCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* deferEfbCell;
@property (weak, nonatomic) IBOutlet UISlider* textureAccuracySlider;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* gpuTextureCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* xfbToTextureCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* presentXfbCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* duplicateFramesCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* fastDepthCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* vertexRoundingCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* boundingBoxCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* textureCacheCell;

@end

NS_ASSUME_NONNULL_END
