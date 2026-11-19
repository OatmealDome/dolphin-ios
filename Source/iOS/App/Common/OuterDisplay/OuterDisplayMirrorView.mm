// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "OuterDisplayMirrorView.h"

#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

#include <algorithm>
#include <chrono>
#include <climits>
#include <cmath>

#include "VideoBackends/Metal/MTLPresentMirror.h"

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
@property(nonatomic) int framesToSkip;
@property(nonatomic) int slowFrameCount;
@end

@implementation DOLMirrorRenderer

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

/// Draws `crop` (in pixels of `source`) into the whole of `target`, keeping the picture's shape
/// (black bars where the shapes differ). One render pass.
- (void)draw:(id<MTLTexture>)source
        crop:(PixelRect)crop
        into:(id<MTLTexture>)target
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
  const double dstW = target.width;
  const double dstH = target.height;
  const double aspect = crop.Width() / crop.Height();

  // Fit inside the target, with black bars.
  double vpW = dstW;
  double vpH = dstW / aspect;
  if (vpH > dstH)
  {
    vpH = dstH;
    vpW = dstH * aspect;
  }

  const float uv[4] = {float(crop.x0 / texW), float(crop.y0 / texH), float(crop.Width() / texW),
                       float(crop.Height() / texH)};
  const MTLViewport viewport = {(dstW - vpW) / 2.0, (dstH - vpH) / 2.0, vpW, vpH, 0.0, 1.0};
  [encoder setViewport:viewport];
  [encoder setVertexBytes:uv length:sizeof(uv) atIndex:0];
  [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];

  [encoder endEncoding];
}

- (void)encodeIntoCommandBuffer:(id<MTLCommandBuffer>)cmdbuf
                     backbuffer:(id<MTLTexture>)backbuffer
                           rect:(CGRect)rect
{
  // If the outer display stops taking frames (for example the system withdrew it),
  // nextDrawable can block for up to a second, which would freeze the game. Back off.
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

  // The game picture inside the backbuffer (Dolphin adds black bars around it).
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

  if (self.layer.drawableSize.width < 1 || self.layer.drawableSize.height < 1)
  {
    return;
  }

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
    [self draw:backbuffer crop:game into:drawable.texture cmdbuf:cmdbuf];
    [cmdbuf presentDrawable:drawable];
  }
}

@end

static void MirrorCallback(void* context, id<MTLCommandBuffer> cmdbuf, id<MTLTexture> backbuffer,
                           int x, int y, int width, int height)
{
  @autoreleasepool
  {
    DOLMirrorRenderer* renderer = (__bridge DOLMirrorRenderer*)context;
    [renderer encodeIntoCommandBuffer:cmdbuf
                           backbuffer:backbuffer
                                 rect:CGRectMake(x, y, width, height)];
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
