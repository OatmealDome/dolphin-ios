// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// A view that shows a live copy of the game picture.
///
/// Between -startMirroring and -stopMirroring, every frame Dolphin presents is also
/// drawn into this view, fitted with black bars. Only one view mirrors at a time;
/// starting a new one replaces the previous one.
///
/// Requires the Metal graphics backend (the DolphiniOS default).
@interface OuterDisplayMirrorView : UIView

- (void)startMirroring;
- (void)stopMirroring;

@end

NS_ASSUME_NONNULL_END
