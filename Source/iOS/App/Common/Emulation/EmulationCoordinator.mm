// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "EmulationCoordinator.h"

#import <MetalKit/MetalKit.h>

#import "Common/WindowSystemInfo.h"

#import "Core/Boot/Boot.h"
#import "Core/BootManager.h"
#import "Core/Core.h"

#import "VideoCommon/RenderBase.h"

#import "EmulationBootParameter.h"
#import "HostNotifications.h"

@implementation EmulationCoordinator {
  NSCondition* _hostJobCondition;
  MTKView* _mtkView;
  CAMetalLayer* _metalLayer;
  UIView* _mainDisplayView;
}

@synthesize userRequestedPause = _userRequestedPause;

+ (EmulationCoordinator*)shared {
  static EmulationCoordinator* sharedInstance = nil;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });

  return sharedInstance;
}

- (id)init {
  if (self = [super init]) {
    _hostJobCondition = [[NSCondition alloc] init];
    
    _mtkView = [[MTKView alloc] init];
    _mtkView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    _metalLayer = (CAMetalLayer*)_mtkView.layer;
    
    self.isExternalDisplayConnected = false;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveDispatchJobNotification) name:DOLHostDidReceiveDispatchJobNotification object:nil];
  }
  
  return self;
}

- (void)setIsExternalDisplayConnected:(bool)connected {
  self->_isExternalDisplayConnected = connected;
  
  if (!_isExternalDisplayConnected) {
    [self requestDisplayOnSuperview:_mainDisplayView];
  }
}

- (void)registerMainDisplayView:(UIView*)mainView {
  _mainDisplayView = mainView;
  
  if (!self.isExternalDisplayConnected) {
    [self requestDisplayOnSuperview:mainView];
  }
}

- (void)registerExternalDisplayView:(UIView*)externalView {
  [self requestDisplayOnSuperview:externalView];
}

- (void)requestDisplayOnSuperview:(UIView*)superview {
  [_mtkView removeFromSuperview];
  
  [superview addSubview:_mtkView];
  [_mtkView setFrame:superview.bounds];
  
  if (g_renderer) {
    g_renderer->ResizeSurface();
  }
}

- (void)runEmulationWithBootParameter:(EmulationBootParameter*)bootParameter {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [self emulationLoopWithBootParameter:bootParameter];
  });
}

- (void)emulationLoopWithBootParameter:(EmulationBootParameter*)bootParameter {
  __block WindowSystemInfo wsi;
  wsi.type = WindowSystemType::iOS;
  wsi.render_surface = (__bridge void*)_metalLayer;
  wsi.render_surface_scale = UIScreen.mainScreen.scale;
  
  std::unique_ptr<BootParameters> boot = [bootParameter generateDolphinBootParameter];
  
  if (!BootManager::BootCore(std::move(boot), wsi)) {
    PanicAlertFmt("Failed to init core!");
    return;
  }
  
  while (Core::GetState() == Core::State::Starting) {
    [NSThread sleepForTimeInterval:0.025];
  }
  
  [[NSNotificationCenter defaultCenter] postNotificationName:DOLEmulationDidStartNotification object:self userInfo:nil];
  
  while (Core::IsRunning()) {
    [_hostJobCondition lock];
    [_hostJobCondition wait];
    
    Core::HostDispatchJobs();
    
    [_hostJobCondition unlock];
  }
  
  [[NSNotificationCenter defaultCenter] postNotificationName:DOLEmulationDidEndNotification object:self userInfo:nil];
  
  _mainDisplayView = nil;
}

- (bool)userRequestedPause {
  return _userRequestedPause;
}

- (void)setUserRequestedPause:(bool)userRequestedPause {
  if (userRequestedPause == _userRequestedPause) {
    return;
  }
  
  Core::SetState(userRequestedPause ? Core::State::Paused : Core::State::Running);
  
  _userRequestedPause = userRequestedPause;
}

- (void)receiveDispatchJobNotification {
  [_hostJobCondition lock];
  [_hostJobCondition signal];
  [_hostJobCondition unlock];
}

- (void)clearMetalLayer {
  id<CAMetalDrawable> drawable = [_metalLayer nextDrawable];
  
  if (drawable == nil) {
    return;
  }
  
  MTLRenderPassDescriptor* renderPass = [MTLRenderPassDescriptor renderPassDescriptor];
  renderPass.colorAttachments[0].texture = drawable.texture;
  renderPass.colorAttachments[0].loadAction = MTLLoadActionClear;
  renderPass.colorAttachments[0].storeAction = MTLStoreActionStore;
  renderPass.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
  
  id<MTLCommandQueue> commandQueue = [_mtkView.preferredDevice newCommandQueue];
  id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
  
  id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPass];
  commandEncoder.label = @"Clear";
  [commandEncoder endEncoding];
 
  [commandBuffer presentDrawable:drawable];
  [commandBuffer commit];
}

@end
