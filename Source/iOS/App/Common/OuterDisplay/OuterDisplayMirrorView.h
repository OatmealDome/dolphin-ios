// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// How the game picture is shared between the inner and outer displays.
typedef NS_ENUM(NSInteger, OuterDisplayLayout) {
  /// Both displays show the whole picture.
  OuterDisplayLayoutMirror = 0,
  /// Split-screen games that stack players top and bottom (also 4-player grids:
  /// the top row goes to one display, the bottom row to the other).
  OuterDisplayLayoutSplitTopBottom = 1,
  /// Split-screen games that put players side by side.
  OuterDisplayLayoutSplitLeftRight = 2,
  /// 3 players in a 2x2 grid (bottom-right unused): players 1 and 2 on the inner display,
  /// player 3 on the outer display.
  OuterDisplayLayoutThreePlayers = 3,
  /// 4 players in a 2x2 grid: players 1 and 2 on the inner display, 3 and 4 side by side
  /// on the outer display.
  OuterDisplayLayoutFourPlayers = 4,
};

/// How two players share the inner display (3- and 4-player layouts).
typedef NS_ENUM(NSInteger, OuterDisplayInnerArrangement) {
  /// Left and right. In laptop posture that is within the top half, above the fold.
  OuterDisplayInnerArrangementSideBySide = 0,
  /// Top and bottom halves of the whole inner display; in laptop posture, one each side of the
  /// fold.
  OuterDisplayInnerArrangementStacked = 1,
};

/// How a picture is fitted onto a display whose shape differs from it.
typedef NS_ENUM(NSInteger, OuterDisplayScaling) {
  /// Show the whole picture, with black bars where the shapes differ.
  OuterDisplayScalingFit = 0,
  /// Fill the display without distorting, trimming the picture's edges.
  OuterDisplayScalingZoom = 1,
};

/// A view that shows a live copy of the game picture.
///
/// Between -startMirroring and -stopMirroring, every frame Dolphin presents is also
/// drawn into this view. In a split layout, the inner display is cropped to one half
/// of the picture and this view shows the other half. Only one view mirrors at a time;
/// starting a new one replaces the previous one.
///
/// Requires the Metal graphics backend (the DolphiniOS default).
@interface OuterDisplayMirrorView : UIView

- (void)startMirroring;
- (void)stopMirroring;

/// Takes effect on the next frame. Safe to call at any time from the main thread.
/// @param swapHalves In a split layout, show the first half (top or left) on the outer
///                   display instead of the inner one. In 4 Players, swaps the rows (the
///                   bottom row goes inside); in 3 Players, swaps players 1 and 2 inside.
/// @param innerArrangement How players 1 and 2 share the inner display (3 and 4 players).
+ (void)setLayout:(OuterDisplayLayout)layout
          swapHalves:(BOOL)swapHalves
    innerArrangement:(OuterDisplayInnerArrangement)innerArrangement;

/// Automatic: show the whole picture on both displays (mirror) during menus and cutscenes,
/// and switch to the matching split layout while the game draws split-screen (detected from
/// the game's viewports each frame). The layout passed to -setLayout: is then used only to
/// prefer 3 Players when a game draws all four quarters for three players.
+ (void)setAutomatic:(BOOL)automatic;

/// What automatic detection currently sees: a split layout, or Mirror when not split-screen
/// (or paused).
+ (OuterDisplayLayout)detectedLayout;

/// Automatic: mirror while the game is paused. Start pressed on any GameCube controller during
/// split-screen counts as pausing; Start, A or B (closing or choosing from the pause menu) ends it.
+ (void)setMirrorWhilePaused:(BOOL)mirrorWhilePaused;

/// Whether automatic mode currently thinks the game is paused.
+ (BOOL)isPaused;

/// How the picture is fitted onto one display. Takes effect on the next frame.
/// The inner display setting only applies in split layouts (in Mirror mode the inner
/// display is Dolphin's own picture).
/// @param stretch 0 keeps the picture's shape, 1 stretches it to the display's shape;
///                values in between stretch part of the way.
+ (void)setScaling:(OuterDisplayScaling)scaling stretch:(float)stretch forOuterDisplay:(BOOL)outer;

@end

/// The games in the library, for picking one to give its own outer screen settings.
@interface OuterDisplayGameLibrary : NSObject

/// One entry per game ID, sorted by name. Keys: @"id", @"title".
+ (NSArray<NSDictionary<NSString*, NSString*>*>*)games;

@end

NS_ASSUME_NONNULL_END
