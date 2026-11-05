// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "EmulationCoordinator.h"

#import <MetalKit/MetalKit.h>

#import "Common/MemoryUtil.h"
#import "Common/WindowSystemInfo.h"

#import "Core/Boot/Boot.h"
#import "Core/BootManager.h"
#import "Core/Config/GraphicsSettings.h"
#import "Core/Config/MainSettings.h"
#import "Core/Core.h"
#import "Core/PowerPC/PowerPC.h"
#import "Core/System.h"

#import "VideoCommon/Present.h"
#import "VideoCommon/VideoConfig.h"

#import "EmulationBootParameter.h"
#import "HostNotifications.h"
#import "HostQueue.h"
#import "JitManager.h"

@implementation EmulationCoordinator
{
  MTKView* _mtkView;
  CAMetalLayer* _metalLayer;
  UIView* _mainDisplayView;
  CGSize _renderSurfaceSize;
  CGFloat _renderSurfaceScale;
}

@synthesize userRequestedPause = _userRequestedPause;

+ (EmulationCoordinator*)shared
{
  static EmulationCoordinator* sharedInstance = nil;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });

  return sharedInstance;
}

- (id)init
{
  if (self = [super init])
  {
    _mtkView = [[MTKView alloc] init];
    _mtkView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _mtkView.preferredFramesPerSecond = 120;

    _metalLayer = (CAMetalLayer*)_mtkView.layer;

    self.isExternalDisplayConnected = false;
  }

  return self;
}

- (void)setIsExternalDisplayConnected:(bool)connected
{
  self->_isExternalDisplayConnected = connected;

  if (!_isExternalDisplayConnected)
  {
    [self requestDisplayOnSuperview:_mainDisplayView];
  }
}

- (void)registerMainDisplayView:(UIView*)mainView
{
  _mainDisplayView = mainView;

  if (!self.isExternalDisplayConnected)
  {
    [self requestDisplayOnSuperview:mainView];
  }
}

- (void)registerExternalDisplayView:(UIView*)externalView
{
  [self requestDisplayOnSuperview:externalView];
}

- (void)requestDisplayOnSuperview:(UIView*)superview
{
  [_mtkView removeFromSuperview];

  [superview addSubview:_mtkView];
  [self updateRenderSurface];
}

- (void)updateRenderSurface
{
  NSAssert([NSThread isMainThread], @"Render surface updates must run on the main thread");

  UIView* superview = _mtkView.superview;
  if (superview == nil || CGRectIsEmpty(superview.bounds))
  {
    return;
  }

  _mtkView.frame = superview.bounds;

  // The same scene can move between the inner and outer displays. Use the
  // renderer's current traits instead of assuming that there is a main screen.
  CGFloat scale = _mtkView.traitCollection.displayScale;
  if (scale <= 0)
  {
    return;
  }

  _mtkView.contentScaleFactor = scale;
  CGSize size = _mtkView.bounds.size;
  if (CGSizeEqualToSize(size, _renderSurfaceSize) && scale == _renderSurfaceScale)
  {
    return;
  }

  _renderSurfaceSize = size;
  _renderSurfaceScale = scale;

  if (g_presenter)
  {
    g_presenter->ResizeSurface();
  }
}

- (void)runEmulationWithBootParameter:(EmulationBootParameter*)bootParameter
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [self emulationLoopWithBootParameter:bootParameter];
  });
}

- (void)emulationLoopWithBootParameter:(EmulationBootParameter*)bootParameter
{
  __block CGFloat renderSurfaceScale;
  dispatch_sync(dispatch_get_main_queue(), ^{
    [self updateRenderSurface];
    renderSurfaceScale = self->_mtkView.contentScaleFactor;
    Core::UndeclareAsHostThread();
  });

  DOLHostQueueRunSync(^{
    __block WindowSystemInfo wsi;
    wsi.type = WindowSystemType::iOS;
    wsi.render_surface = (__bridge void*)self->_metalLayer;
    wsi.render_surface_scale = renderSurfaceScale;

    auto& system = Core::System::GetInstance();

    if ([JitManager shared].acquiredJit)
    {
      if (@available(iOS 26, *))
      {
        Common::SetJitType([JitManager shared].deviceHasTxm ? Common::JitType::LuckTXM :
                                                              Common::JitType::LuckNoTXM);
      }
      else
      {
        Common::SetJitType(Common::JitType::Legacy);
      }

      Config::SetBase(Config::GFX_VERTEX_LOADER_TYPE, VertexLoaderType::Native);

      Common::AllocateExecutableMemoryRegion();
    }
    else
    {
      Config::SetBase(Config::GFX_VERTEX_LOADER_TYPE, VertexLoaderType::Software);
    }

    std::unique_ptr<BootParameters> boot = [bootParameter generateDolphinBootParameter];

    if (!BootManager::BootCore(system, std::move(boot), wsi))
    {
      PanicAlertFmt("Failed to init core!");
    }
  });

  while (Core::GetState(Core::System::GetInstance()) == Core::State::Starting)
  {
    [NSThread sleepForTimeInterval:0.025];
  }

  [[NSNotificationCenter defaultCenter] postNotificationName:DOLEmulationDidStartNotification
                                                      object:self
                                                    userInfo:nil];

  while (Core::IsRunning(Core::System::GetInstance()))
  {
    [NSThread sleepForTimeInterval:0.025];
  }

  dispatch_sync(dispatch_get_main_queue(), ^{
    Core::DeclareAsHostThread();
    self->_mainDisplayView = nil;
  });

  [[NSNotificationCenter defaultCenter] postNotificationName:DOLEmulationDidEndNotification
                                                      object:self
                                                    userInfo:nil];
}

- (bool)userRequestedPause
{
  return _userRequestedPause;
}

- (void)setUserRequestedPause:(bool)userRequestedPause
{
  if (userRequestedPause == _userRequestedPause)
  {
    return;
  }

  DOLHostQueueRunSync(^{
    Core::SetState(Core::System::GetInstance(),
                   userRequestedPause ? Core::State::Paused : Core::State::Running);
  });

  _userRequestedPause = userRequestedPause;
}

- (void)clearMetalLayer
{
  id<CAMetalDrawable> drawable = [_metalLayer nextDrawable];

  if (drawable == nil)
  {
    return;
  }

  MTLRenderPassDescriptor* renderPass = [MTLRenderPassDescriptor renderPassDescriptor];
  renderPass.colorAttachments[0].texture = drawable.texture;
  renderPass.colorAttachments[0].loadAction = MTLLoadActionClear;
  renderPass.colorAttachments[0].storeAction = MTLStoreActionStore;
  renderPass.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);

  id<MTLCommandQueue> commandQueue = [_mtkView.preferredDevice newCommandQueue];
  id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

  id<MTLRenderCommandEncoder> commandEncoder =
      [commandBuffer renderCommandEncoderWithDescriptor:renderPass];
  commandEncoder.label = @"Clear";
  [commandEncoder endEncoding];

  [commandBuffer presentDrawable:drawable];
  [commandBuffer commit];
}

@end
