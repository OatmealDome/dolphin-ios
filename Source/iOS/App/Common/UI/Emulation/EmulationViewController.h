// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>
#import <MetalKit/MetalKit.h>

#import "Swift.h"

@class EmulationBootParameter;

NS_ASSUME_NONNULL_BEGIN

@interface EmulationViewController : UIViewController <JitWaitViewControllerDelegate, NKitWarningViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView* rendererView;

@property (nonatomic) UIBarButtonItem* stopButton;
@property (nonatomic) UIBarButtonItem* pauseButton;
@property (nonatomic) UIBarButtonItem* playButton;
@property (nonatomic) UIBarButtonItem* hideBarButton;

@property (nonatomic) EmulationBootParameter* bootParameter;

- (void)updateNavigationBar:(bool)hidden;

@end

NS_ASSUME_NONNULL_END
