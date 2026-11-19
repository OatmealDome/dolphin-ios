// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "OuterDisplayMirrorView.h"

#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>
#import <os/log.h>

#include <algorithm>
#include <atomic>
#include <chrono>
#include <climits>
#include <cmath>
#include <utility>
#include <vector>

#include "VideoBackends/Metal/MTLPresentMirror.h"

#include "Core/HW/GCPad.h"
#include "InputCommon/GCPadStatus.h"

static const char* const kMirrorShaderSource = R"(
#include <metal_stdlib>
using namespace metal;

struct MirrorVertexOut {
  float4 position [[position]];
  float2 uv;
};

// One triangle that covers the whole viewport. `crop` is (u, v, width, height)
// of the source texture, in 0..1 texture coordinates.
vertex MirrorVertexOut mirror_vs(uint vid [[vertex_id]], constant float4& crop [[buffer(0)]]) {
  float2 p = float2((vid << 1) & 2, vid & 2);
  MirrorVertexOut out;
  out.position = float4(p * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
  out.uv = crop.xy + p * crop.zw;
  return out;
}

fragment float4 mirror_fs(MirrorVertexOut in [[stage_in]],
                          texture2d<float> source [[texture(0)]],
                          sampler linear_sampler [[sampler(0)]]) {
  return source.sample(linear_sampler, in.uv);
}
)";

// Layout settings: written on the main thread, read on the video thread every frame.
static std::atomic<int> s_layout{OuterDisplayLayoutMirror};
static std::atomic<bool> s_swapHalves{false};
static std::atomic<int> s_innerArrangement{OuterDisplayInnerArrangementSideBySide};
// Automatic: mirror until the game draws split-screen, then use the detected layout.
static std::atomic<bool> s_automatic{false};
// What automatic detection currently sees (OuterDisplayLayoutMirror when not split-screen).
static std::atomic<int> s_detectedLayout{OuterDisplayLayoutMirror};
// Automatic: go back to mirroring while the game is paused (Start pressed mid-race).
static std::atomic<bool> s_mirrorWhilePaused{true};
static std::atomic<bool> s_paused{false};
// Index 0 = inner display, 1 = outer display.
static std::atomic<int> s_scaling[2] = {OuterDisplayScalingFit, OuterDisplayScalingFit};
static std::atomic<float> s_stretch[2] = {0.0f, 0.0f};

namespace
{
// A rectangle in texture pixels.
struct PixelRect
{
  double x0, y0, x1, y1;
  double Width() const { return x1 - x0; }
  double Height() const { return y1 - y0; }
};
}  // namespace

/// Everything the video thread touches. Owned by the view and handed to the core as the
/// callback context. While registered, only the video thread uses it.
@interface DOLMirrorRenderer : NSObject
@property(nonatomic, strong) CAMetalLayer* layer;
@property(nonatomic, strong) id<MTLRenderPipelineState> pipeline;
@property(nonatomic, strong) id<MTLSamplerState> sampler;
@property(nonatomic, strong) id<MTLDevice> pipelineDevice;
@property(nonatomic) MTLPixelFormat pipelineFormat;
@property(nonatomic, strong) id<MTLTexture>
    scratch;  // Copy of the game picture, for split layouts.
@property(nonatomic) int framesToSkip;
@property(nonatomic) int slowFrameCount;
// Automatic layout: the candidate layout and for how many frames in a row it was seen.
@property(nonatomic) OuterDisplayLayout candidateLayout;
@property(nonatomic) int candidateFrames;
// Diagnostics: the last logged set of viewports, so only changes are logged.
@property(nonatomic, copy) NSString* lastViewportSignature;
@end

@implementation DOLMirrorRenderer
{
  uint16_t _previousButtons[4];  // GameCube pad buttons last frame, for press detection.
  BOOL _logViewports;            // Diagnostics, from the outer_display_log_viewports default.
  BOOL _readLogDefault;
}

- (BOOL)prepareForDevice:(id<MTLDevice>)device format:(MTLPixelFormat)format
{
  if (self.pipeline && self.pipelineFormat == format && self.pipelineDevice == device)
  {
    return YES;
  }

  NSError* error = nil;
  NSString* source = [NSString stringWithUTF8String:kMirrorShaderSource];
  id<MTLLibrary> library = [device newLibraryWithSource:source options:nil error:&error];
  if (!library)
  {
    NSLog(@"[OuterDisplayMirror] Shader compile failed: %@", error);
    return NO;
  }

  MTLRenderPipelineDescriptor* desc = [[MTLRenderPipelineDescriptor alloc] init];
  desc.label = @"Outer Display Mirror";
  desc.vertexFunction = [library newFunctionWithName:@"mirror_vs"];
  desc.fragmentFunction = [library newFunctionWithName:@"mirror_fs"];
  desc.colorAttachments[0].pixelFormat = format;

  self.pipeline = [device newRenderPipelineStateWithDescriptor:desc error:&error];
  if (!self.pipeline)
  {
    NSLog(@"[OuterDisplayMirror] Pipeline creation failed: %@", error);
    return NO;
  }

  MTLSamplerDescriptor* samplerDesc = [[MTLSamplerDescriptor alloc] init];
  samplerDesc.minFilter = MTLSamplerMinMagFilterLinear;
  samplerDesc.magFilter = MTLSamplerMinMagFilterLinear;
  samplerDesc.sAddressMode = MTLSamplerAddressModeClampToEdge;
  samplerDesc.tAddressMode = MTLSamplerAddressModeClampToEdge;
  self.sampler = [device newSamplerStateWithDescriptor:samplerDesc];

  // Match Dolphin's device and pixel format so every copy is a straight resample.
  self.layer.device = device;
  self.layer.pixelFormat = format;
  self.pipelineDevice = device;
  self.pipelineFormat = format;
  return YES;
}

/// Copies `rect` of `source` into the scratch texture (resized as needed) and returns it.
- (id<MTLTexture>)copyToScratch:(id<MTLTexture>)source
                           rect:(PixelRect)rect
                         cmdbuf:(id<MTLCommandBuffer>)cmdbuf
{
  const NSUInteger width = (NSUInteger)rect.Width();
  const NSUInteger height = (NSUInteger)rect.Height();

  if (!self.scratch || self.scratch.width != width || self.scratch.height != height ||
      self.scratch.pixelFormat != source.pixelFormat)
  {
    MTLTextureDescriptor* desc =
        [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:source.pixelFormat
                                                           width:width
                                                          height:height
                                                       mipmapped:NO];
    desc.usage = MTLTextureUsageShaderRead;
    desc.storageMode = MTLStorageModePrivate;
    self.scratch = [cmdbuf.device newTextureWithDescriptor:desc];
    self.scratch.label = @"Outer Display Split Scratch";
  }

  id<MTLBlitCommandEncoder> blit = [cmdbuf blitCommandEncoder];
  blit.label = @"Outer Display Split Copy";
  [blit copyFromTexture:source
            sourceSlice:0
            sourceLevel:0
           sourceOrigin:MTLOriginMake((NSUInteger)rect.x0, (NSUInteger)rect.y0, 0)
             sourceSize:MTLSizeMake(width, height, 1)
              toTexture:self.scratch
       destinationSlice:0
       destinationLevel:0
      destinationOrigin:MTLOriginMake(0, 0, 0)];
  [blit endEncoding];

  return self.scratch;
}

/// Draws each crop (in pixels of `source`) into its region of `target` (in pixels of `target`),
/// fitted per `scaling`/`stretch`, after clearing the whole target to black. One render pass.
- (void)draw:(id<MTLTexture>)source
       views:(const std::vector<std::pair<PixelRect, PixelRect>>&)views
        into:(id<MTLTexture>)target
     scaling:(OuterDisplayScaling)scaling
     stretch:(double)stretch
      cmdbuf:(id<MTLCommandBuffer>)cmdbuf
{
  MTLRenderPassDescriptor* pass = [MTLRenderPassDescriptor renderPassDescriptor];
  pass.colorAttachments[0].texture = target;
  pass.colorAttachments[0].loadAction = MTLLoadActionClear;
  pass.colorAttachments[0].storeAction = MTLStoreActionStore;
  pass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1);

  id<MTLRenderCommandEncoder> encoder = [cmdbuf renderCommandEncoderWithDescriptor:pass];
  encoder.label = @"Outer Display Mirror";
  [encoder setRenderPipelineState:self.pipeline];
  [encoder setFragmentTexture:source atIndex:0];
  [encoder setFragmentSamplerState:self.sampler atIndex:0];

  const double texW = source.width;
  const double texH = source.height;

  for (const auto& [crop, region] : views)
  {
    if (crop.Width() < 1 || crop.Height() < 1 || region.Width() < 1 || region.Height() < 1)
    {
      continue;
    }

    const double dstW = region.Width();
    const double dstH = region.Height();
    const double dstAspect = dstW / dstH;

    // The shape the picture is shown at: its own shape at stretch 0, the region's at 1,
    // and in between (geometric blend, so 50% feels halfway either way) otherwise.
    const double srcAspect = crop.Width() / crop.Height();
    const double t = std::clamp(stretch, 0.0, 1.0);
    const double aspect = std::pow(srcAspect, 1.0 - t) * std::pow(dstAspect, t);

    double vpW = dstW;
    double vpH = dstH;
    PixelRect sample = crop;
    if (scaling == OuterDisplayScalingZoom)
    {
      // Fill the region; trim the picture's edges (centred) instead of adding bars.
      if (aspect > dstAspect)
      {
        const double keep = crop.Width() * (dstAspect / aspect);
        sample.x0 = crop.x0 + (crop.Width() - keep) / 2;
        sample.x1 = sample.x0 + keep;
      }
      else
      {
        const double keep = crop.Height() * (aspect / dstAspect);
        sample.y0 = crop.y0 + (crop.Height() - keep) / 2;
        sample.y1 = sample.y0 + keep;
      }
    }
    else
    {
      // Fit inside the region, with black bars.
      vpH = dstW / aspect;
      if (vpH > dstH)
      {
        vpH = dstH;
        vpW = dstH * aspect;
      }
    }

    const float uv[4] = {float(sample.x0 / texW), float(sample.y0 / texH),
                         float(sample.Width() / texW), float(sample.Height() / texH)};
    const MTLViewport viewport = {
        region.x0 + (dstW - vpW) / 2.0, region.y0 + (dstH - vpH) / 2.0, vpW, vpH, 0.0, 1.0};
    [encoder setViewport:viewport];
    [encoder setVertexBytes:uv length:sizeof(uv) atIndex:0];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
  }

  [encoder endEncoding];
}

/// Regions for `count` views across a `width` x `height` target: the whole target for one view;
/// for two, left/right halves, or top/bottom halves when `stacked`.
static std::vector<PixelRect> Regions(size_t count, double width, double height, bool stacked)
{
  if (count <= 1)
  {
    return {{0, 0, width, height}};
  }
  if (stacked)
  {
    const double mid = std::floor(height / 2);
    return {{0, 0, width, mid}, {0, mid, width, height}};
  }
  const double mid = std::floor(width / 2);
  return {{0, 0, mid, height}, {mid, 0, width, height}};
}

/// Works out from one frame's viewports (native EFB pixels) whether the game is split-screen.
/// Split-screen games draw each player's view in its own viewport, and those views tile the
/// screen: two halves, or three or four quarters. Menus and cutscenes draw full-screen.
/// Small viewports (previews, render-to-texture effects) and ones that don't tile are ignored.
static OuterDisplayLayout ClassifyViewports(const float* viewports, int count)
{
  std::vector<PixelRect> rects;
  for (int i = 0; i < count; i++)
  {
    const PixelRect r = {viewports[i * 4], viewports[i * 4 + 1], viewports[i * 4 + 2],
                         viewports[i * 4 + 3]};
    if (r.Width() >= 120 && r.Height() >= 90)
    {
      rects.push_back(r);
    }
  }
  if (rects.empty())
  {
    return OuterDisplayLayoutMirror;
  }

  // The screen area the game draws to: the bounding box of the big viewports.
  PixelRect screen = rects[0];
  for (const auto& r : rects)
  {
    screen = {std::min(screen.x0, r.x0), std::min(screen.y0, r.y0), std::max(screen.x1, r.x1),
              std::max(screen.y1, r.y1)};
  }
  if (screen.Width() < 440 || screen.Height() < 300)
  {
    return OuterDisplayLayoutMirror;
  }

  auto near = [](double value, double target, double tolerance) {
    return std::abs(value - target) <= tolerance;
  };
  const double sw = screen.Width();
  const double sh = screen.Height();
  const double midX = screen.x0 + sw / 2;
  const double midY = screen.y0 + sh / 2;

  bool top = false, bottom = false, left = false, right = false;
  bool quarter[4] = {false, false, false, false};  // TL, TR, BL, BR

  for (const auto& r : rects)
  {
    const bool fullW = r.Width() >= sw * 0.9;
    const bool fullH = r.Height() >= sh * 0.9;
    const bool halfW = near(r.Width(), sw / 2, sw * 0.08);
    const bool halfH = near(r.Height(), sh / 2, sh * 0.08);
    const bool isTop = near(r.y0, screen.y0, sh * 0.05);
    const bool isBottom = near(r.y1, screen.y1, sh * 0.05);
    const bool isLeft = near(r.x0, screen.x0, sw * 0.05);
    const bool isRight = near(r.x1, screen.x1, sw * 0.05);

    if (fullW && halfH)
    {
      if (isTop)
        top = true;
      if (isBottom)
        bottom = true;
    }
    else if (fullH && halfW)
    {
      if (isLeft)
        left = true;
      if (isRight)
        right = true;
    }
    else if (halfW && halfH)
    {
      const int column = (r.x0 + r.x1) / 2 < midX ? 0 : 1;
      const int row = (r.y0 + r.y1) / 2 < midY ? 0 : 1;
      if ((column == 0 ? isLeft : isRight) && (row == 0 ? isTop : isBottom))
      {
        quarter[row * 2 + column] = true;
      }
    }
  }

  const int quarters = quarter[0] + quarter[1] + quarter[2] + quarter[3];
  if (quarters >= 3)
  {
    return quarters == 4 ? OuterDisplayLayoutFourPlayers : OuterDisplayLayoutThreePlayers;
  }
  if (top && bottom)
  {
    return OuterDisplayLayoutSplitTopBottom;
  }
  if (left && right)
  {
    return OuterDisplayLayoutSplitLeftRight;
  }
  return OuterDisplayLayoutMirror;
}

static NSString* LayoutName(OuterDisplayLayout layout)
{
  switch (layout)
  {
  case OuterDisplayLayoutSplitTopBottom:
    return @"2 players (top & bottom)";
  case OuterDisplayLayoutSplitLeftRight:
    return @"2 players (left & right)";
  case OuterDisplayLayoutThreePlayers:
    return @"3 players";
  case OuterDisplayLayoutFourPlayers:
    return @"4 players";
  default:
    return @"not split-screen";
  }
}

/// Feeds one frame's viewports to automatic detection and returns the layout to use now.
/// A change must be seen for several frames in a row before it is used, so fades, loading
/// screens and one-off effects don't make the screens flicker between layouts.
- (OuterDisplayLayout)automaticLayoutForViewports:(const float*)viewports count:(int)count
{
  const auto current = (OuterDisplayLayout)s_detectedLayout.load();
  if (count == 0)
  {
    return current;  // Nothing drawn this frame (repeated frame); keep what we have.
  }

  const OuterDisplayLayout seen = ClassifyViewports(viewports, count);

  // Diagnostics (off unless the outer_display_log_viewports default is set): log the frame's
  // viewports whenever the set changes, rounded so tiny differences don't flood the log.
  // Shown in Console.app; filter "OuterDisplayMirror".
  if (!_readLogDefault)
  {
    _readLogDefault = YES;
    _logViewports =
        [[NSUserDefaults standardUserDefaults] boolForKey:@"outer_display_log_viewports"];
  }
  if (_logViewports)
  {
    NSMutableString* signature = [NSMutableString string];
    for (int i = 0; i < count && i < 16; i++)
    {
      [signature appendFormat:@" [%d,%d-%d,%d]", (int)(viewports[i * 4] / 8) * 8,
                              (int)(viewports[i * 4 + 1] / 8) * 8,
                              (int)(viewports[i * 4 + 2] / 8) * 8,
                              (int)(viewports[i * 4 + 3] / 8) * 8];
    }
    if (![signature isEqualToString:self.lastViewportSignature ?: @""])
    {
      self.lastViewportSignature = signature;
      os_log(OS_LOG_DEFAULT, "[OuterDisplayMirror] Viewports (%d):%{public}@ -> %{public}@", count,
             signature, LayoutName(seen));
    }
  }
  if (seen == current)
  {
    self.candidateFrames = 0;
    return current;
  }

  if (seen != self.candidateLayout)
  {
    self.candidateLayout = seen;
    self.candidateFrames = 0;
  }

  // Switching into split-screen waits a little longer than switching back out, so a menu
  // that briefly draws something grid-like doesn't split the screens.
  const int needed = seen == OuterDisplayLayoutMirror ? 10 : 20;
  if (++self.candidateFrames < needed)
  {
    return current;
  }

  NSMutableString* rects = [NSMutableString string];
  for (int i = 0; i < count && i < 8; i++)
  {
    [rects appendFormat:@" [%.0f,%.0f-%.0f,%.0f]", viewports[i * 4], viewports[i * 4 + 1],
                        viewports[i * 4 + 2], viewports[i * 4 + 3]];
  }
  os_log(OS_LOG_DEFAULT, "[OuterDisplayMirror] Automatic: now %{public}@ (viewports:%{public}@)",
         LayoutName(seen), rects);

  s_detectedLayout.store((int)seen);
  self.candidateFrames = 0;

  // The inner display may need the whole screen (or only the top half) for the new layout.
  dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"OuterDisplayLayoutDidChange"
                                                        object:nil];
  });
  return seen;
}

/// Buttons newly pressed this frame on any GameCube controller port, as the game sees them
/// (after mapping, so it works with any controller, and with the touch controls).
- (uint16_t)newlyPressedButtons
{
  if (!Pad::IsInitialized())
  {
    return 0;
  }
  uint16_t pressed = 0;
  for (int i = 0; i < 4; i++)
  {
    const uint16_t buttons = Pad::GetStatus(i).button;
    pressed |= buttons & ~_previousButtons[i];
    _previousButtons[i] = buttons;
  }
  return pressed;
}

/// Pause tracking for automatic mode. Games usually draw their pause menu over the frozen
/// split-screen views, so it can't be told apart from racing by what is drawn. Instead:
/// Start pressed during split-screen counts as paused (mirror); Start, A or B ends it (those
/// close or choose from the pause menu). Leaving split-screen also ends it.
- (bool)updatePausedForSplit:(bool)split
{
  const uint16_t pressed = [self newlyPressedButtons];
  bool paused = s_paused.load();
  const bool wasPaused = paused;

  if (!split || !s_mirrorWhilePaused.load())
  {
    paused = false;
  }
  else if (!paused && (pressed & PAD_BUTTON_START))
  {
    paused = true;
  }
  else if (paused && (pressed & (PAD_BUTTON_START | PAD_BUTTON_A | PAD_BUTTON_B)))
  {
    paused = false;
  }

  if (paused != wasPaused)
  {
    s_paused.store(paused);
    os_log(OS_LOG_DEFAULT, "[OuterDisplayMirror] Automatic: %{public}s",
           paused ? "paused, mirroring" : "resumed");
    dispatch_async(dispatch_get_main_queue(), ^{
      [[NSNotificationCenter defaultCenter] postNotificationName:@"OuterDisplayLayoutDidChange"
                                                          object:nil];
    });
  }
  return paused;
}

- (void)encodeIntoCommandBuffer:(id<MTLCommandBuffer>)cmdbuf
                     backbuffer:(id<MTLTexture>)backbuffer
                           rect:(CGRect)rect
                      viewports:(const float*)viewports
                  viewportCount:(int)viewportCount
{
  // If the outer display stops taking frames (for example the system withdrew it),
  // nextDrawable can block for up to a second, which would freeze the game. Back off.
  // While backed off the inner display shows the whole picture, so no player loses their view.
  if (self.framesToSkip > 0)
  {
    self.framesToSkip--;
    return;
  }

  if (![self prepareForDevice:cmdbuf.device format:backbuffer.pixelFormat])
  {
    self.framesToSkip = INT_MAX;  // Can't render at all; stop trying.
    return;
  }

  OuterDisplayLayout layout = (OuterDisplayLayout)s_layout.load();
  if (s_automatic.load())
  {
    const OuterDisplayLayout detected = [self automaticLayoutForViewports:viewports
                                                                    count:viewportCount];
    // A game whose unused fourth quarter is still drawn looks like 4 players; if the chosen
    // layout is 3 Players, trust that instead.
    if (detected == OuterDisplayLayoutFourPlayers && layout == OuterDisplayLayoutThreePlayers)
    {
      layout = OuterDisplayLayoutThreePlayers;
    }
    else
    {
      layout = detected;
    }
    if ([self updatePausedForSplit:detected != OuterDisplayLayoutMirror])
    {
      layout = OuterDisplayLayoutMirror;
    }
  }
  const bool swapHalves = s_swapHalves.load();
  const bool stacked = s_innerArrangement.load() == OuterDisplayInnerArrangementStacked;
  const auto innerScaling = (OuterDisplayScaling)s_scaling[0].load();
  const auto outerScaling = (OuterDisplayScaling)s_scaling[1].load();
  const double innerStretch = s_stretch[0].load();
  const double outerStretch = s_stretch[1].load();

  // The game picture inside the backbuffer (Dolphin adds black bars around it).
  // Rounded to whole pixels so it can be copied exactly.
  const double texW = backbuffer.width;
  const double texH = backbuffer.height;
  const PixelRect game = {
      std::round(std::clamp<double>(rect.origin.x, 0, texW)),
      std::round(std::clamp<double>(rect.origin.y, 0, texH)),
      std::round(std::clamp<double>(rect.origin.x + rect.size.width, 0, texW)),
      std::round(std::clamp<double>(rect.origin.y + rect.size.height, 0, texH)),
  };
  if (game.Width() < 2 || game.Height() < 2)
  {
    return;
  }

  const bool split = layout != OuterDisplayLayoutMirror;

  // Which parts of the picture go on each display (in the picture's own pixels once copied).
  id<MTLTexture> picture = backbuffer;
  std::vector<PixelRect> innerViews;
  std::vector<PixelRect> outerViews = {game};

  if (split)
  {
    // Copy the picture out first: the inner display's views are about to be drawn over
    // the backbuffer they came from.
    picture = [self copyToScratch:backbuffer rect:game cmdbuf:cmdbuf];

    const double w = game.Width();
    const double h = game.Height();
    const double midX = std::floor(w / 2);
    const double midY = std::floor(h / 2);

    std::vector<PixelRect> first, second;  // Without swap: first → inner, second → outer.
    switch (layout)
    {
    case OuterDisplayLayoutSplitTopBottom:
      first = {{0, 0, w, midY}};
      second = {{0, midY, w, h}};
      break;
    case OuterDisplayLayoutSplitLeftRight:
      first = {{0, 0, midX, h}};
      second = {{midX, 0, w, h}};
      break;
    case OuterDisplayLayoutThreePlayers:
      // 2x2 grid with the bottom-right quarter unused: players 1 and 2 (top row) inside,
      // player 3 (bottom left) outside.
      first = {{0, 0, midX, midY}, {midX, 0, w, midY}};
      second = {{0, midY, midX, h}};
      break;
    case OuterDisplayLayoutFourPlayers:
    default:
      // 2x2 grid: players 1 and 2 (top row) inside, players 3 and 4 (bottom row) outside.
      first = {{0, 0, midX, midY}, {midX, 0, w, midY}};
      second = {{0, midY, midX, h}, {midX, midY, w, h}};
      break;
    }

    if (layout == OuterDisplayLayoutThreePlayers)
    {
      // Players 1 and 2 always stay inside: player 3 alone gets the smaller outer display.
      // Swap only switches which of the two takes the left (or top) spot.
      innerViews = first;
      if (swapHalves)
      {
        std::swap(innerViews[0], innerViews[1]);
      }
      outerViews = second;
    }
    else
    {
      innerViews = swapHalves ? second : first;
      outerViews = swapHalves ? first : second;
    }
  }

  auto place = [](const std::vector<PixelRect>& crops, double width, double height, bool stacked) {
    const std::vector<PixelRect> regions = Regions(crops.size(), width, height, stacked);
    std::vector<std::pair<PixelRect, PixelRect>> views;
    for (size_t i = 0; i < crops.size() && i < regions.size(); i++)
    {
      views.emplace_back(crops[i], regions[i]);
    }
    return views;
  };

  // Outer display. Two views always go side by side: it is a wide landscape screen.
  if (self.layer.drawableSize.width >= 1 && self.layer.drawableSize.height >= 1)
  {
    const auto start = std::chrono::steady_clock::now();
    id<CAMetalDrawable> drawable = [self.layer nextDrawable];
    const auto waited = std::chrono::steady_clock::now() - start;

    if (waited > std::chrono::milliseconds(20))
    {
      if (++self.slowFrameCount >= 3)
      {
        NSLog(@"[OuterDisplayMirror] Outer display is not keeping up; pausing it for 240 frames");
        self.slowFrameCount = 0;
        self.framesToSkip = 240;
      }
    }
    else
    {
      self.slowFrameCount = 0;
    }

    if (drawable)
    {
      id<MTLTexture> target = drawable.texture;
      [self draw:picture
            views:place(outerViews, target.width, target.height, false)
             into:target
          scaling:outerScaling
          stretch:outerStretch
           cmdbuf:cmdbuf];
      [cmdbuf presentDrawable:drawable];
    }
  }

  // Inner display: in a split layout, replace the whole picture with this display's views.
  if (split)
  {
    [self draw:picture
          views:place(innerViews, backbuffer.width, backbuffer.height, stacked)
           into:backbuffer
        scaling:innerScaling
        stretch:innerStretch
         cmdbuf:cmdbuf];
  }
}

@end

static void MirrorCallback(void* context, id<MTLCommandBuffer> cmdbuf, id<MTLTexture> backbuffer,
                           int x, int y, int width, int height, const float* viewports,
                           int viewport_count)
{
  @autoreleasepool
  {
    DOLMirrorRenderer* renderer = (__bridge DOLMirrorRenderer*)context;
    [renderer encodeIntoCommandBuffer:cmdbuf
                           backbuffer:backbuffer
                                 rect:CGRectMake(x, y, width, height)
                            viewports:viewports
                        viewportCount:viewport_count];
  }
}

// The renderer currently registered with the core. Holding it here keeps it alive
// while the core may still call into it.
static DOLMirrorRenderer* s_activeRenderer = nil;

@implementation OuterDisplayMirrorView
{
  DOLMirrorRenderer* _renderer;
}

+ (Class)layerClass
{
  return [CAMetalLayer class];
}

+ (void)setLayout:(OuterDisplayLayout)layout
          swapHalves:(BOOL)swapHalves
    innerArrangement:(OuterDisplayInnerArrangement)innerArrangement
{
  s_layout.store((int)layout);
  s_swapHalves.store(swapHalves);
  s_innerArrangement.store((int)innerArrangement);
}

+ (void)setAutomatic:(BOOL)automatic
{
  if (!automatic)
  {
    s_detectedLayout.store(OuterDisplayLayoutMirror);
    s_paused.store(false);
  }
  s_automatic.store(automatic);
}

+ (OuterDisplayLayout)detectedLayout
{
  return s_paused.load() ? OuterDisplayLayoutMirror : (OuterDisplayLayout)s_detectedLayout.load();
}

+ (BOOL)isPaused
{
  return s_paused.load();
}

+ (void)setMirrorWhilePaused:(BOOL)mirrorWhilePaused
{
  s_mirrorWhilePaused.store(mirrorWhilePaused);
}

+ (void)setScaling:(OuterDisplayScaling)scaling stretch:(float)stretch forOuterDisplay:(BOOL)outer
{
  const int i = outer ? 1 : 0;
  s_scaling[i].store((int)scaling);
  s_stretch[i].store(std::clamp(stretch, 0.0f, 1.0f));
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame])
  {
    self.backgroundColor = UIColor.blackColor;
    self.userInteractionEnabled = NO;

    CAMetalLayer* layer = (CAMetalLayer*)self.layer;
    layer.opaque = YES;
    layer.framebufferOnly = YES;
    layer.maximumDrawableCount = 3;
    layer.allowsNextDrawableTimeout = YES;

    _renderer = [[DOLMirrorRenderer alloc] init];
    _renderer.layer = layer;
  }
  return self;
}

- (void)layoutSubviews
{
  [super layoutSubviews];

  CGFloat scale = self.window.screen.nativeScale;
  if (scale <= 0)
  {
    scale = self.traitCollection.displayScale > 0 ? self.traitCollection.displayScale : 3.0;
  }
  self.layer.contentsScale = scale;
  ((CAMetalLayer*)self.layer).drawableSize =
      CGSizeMake(self.bounds.size.width * scale, self.bounds.size.height * scale);
}

- (void)startMirroring
{
  NSAssert(NSThread.isMainThread, @"Call on the main thread");

  _renderer.framesToSkip = 0;
  _renderer.slowFrameCount = 0;
  s_activeRenderer = _renderer;
  Metal::SetPresentMirrorCallback(MirrorCallback, (__bridge void*)_renderer);
}

- (void)stopMirroring
{
  NSAssert(NSThread.isMainThread, @"Call on the main thread");

  if (s_activeRenderer != _renderer)
  {
    return;
  }

  // Returns once any frame being mirrored right now has finished.
  Metal::SetPresentMirrorCallback(nullptr, nullptr);
  s_activeRenderer = nil;
}

- (void)dealloc
{
  if (s_activeRenderer == _renderer)
  {
    Metal::SetPresentMirrorCallback(nullptr, nullptr);
    s_activeRenderer = nil;
  }
}

@end
