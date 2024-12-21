// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "GraphicsTabViewController.h"

#import "DOLSwitch.h"
#import "GraphicsBoolCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface GraphicsAdvancedViewController : GraphicsTabViewController

@property (weak, nonatomic) IBOutlet GraphicsBoolCell* fpsCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* vpsCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* speedCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* frameTimesCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* vblankTimesCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* graphsCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* renderTimeCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* colorsCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* statisticsCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* apiValidationCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* loadTexturesCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* prefetchTexturesCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* disableEfbVramCell;
@property (weak, nonatomic) IBOutlet DOLUIKitSwitch* graphicsModsSwitch;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* cropCell;
@property (weak, nonatomic) IBOutlet DOLUIKitSwitch* progressiveScanSwitch;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* backendMultithreadingCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* vsPointLineExpansionCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* cpuCullCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* deferEfbCacheCell;
@property (weak, nonatomic) IBOutlet GraphicsBoolCell* manualSamplingCell;

@end

NS_ASSUME_NONNULL_END
