// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "EmulationiOSViewController.h"

#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

#import "Common/IOFile.h"

#import "Core/Config/MainSettings.h"
#import "Core/Config/WiimoteSettings.h"
#import "Core/Config/iOSSettings.h"
#import "Core/ConfigManager.h"
#import "Core/HW/GCPad.h"
#import "Core/HW/SI/SI_Device.h"
#import "Core/HW/Wiimote.h"
#import "Core/HW/WiimoteEmu/WiimoteEmu.h"
#import "Core/IOS/USB/Emulated/Skylanders/Skylander.h"
#import "Core/State.h"
#import "Core/System.h"

#import "InputCommon/InputConfig.h"

#import "VideoCommon/Present.h"

#import "EmulationCoordinator.h"
#import "HostNotifications.h"
#import "HostQueue.h"
#import "LocalizationUtil.h"
#import "VirtualMFiControllerManager.h"

typedef NS_ENUM(NSInteger, DOLEmulationVisibleTouchPad) {
  DOLEmulationVisibleTouchPadNone,
  DOLEmulationVisibleTouchPadGameCube,
  DOLEmulationVisibleTouchPadWiimote,
  DOLEmulationVisibleTouchPadSidewaysWiimote,
  DOLEmulationVisibleTouchPadClassic
};

// These hosts stay alive for the entire game, including display and fold transitions.
// Reading reserved regions during updateConstraints opts into UIKit's automatic
// invalidation when a camera obstruction or the active division changes.
@interface DOLGameplayLayoutView : UIView
@property(nonatomic, copy) void (^layoutHandler)(void);
@property(nonatomic, copy) NSArray<NSValue*>* reservedFrames;
- (CGRect)usableBounds;
@end

@implementation DOLGameplayLayoutView

+ (BOOL)requiresConstraintBasedLayout
{
  return YES;
}

- (void)updateConstraints
{
  if (@available(iOS 27.1, *))
  {
    NSMutableArray<NSValue*>* frames = [NSMutableArray array];
    for (UIViewReservedRegionKind* kind in @[
           UIViewReservedRegionKind.occlusionRegionKind, UIViewReservedRegionKind.divisionRegionKind
         ])
    {
      for (UIViewReservedRegion* region in [self reservedRegionsOfKind:kind])
      {
        [frames addObject:[NSValue valueWithCGRect:region.frame]];
      }
    }
    if (![self.reservedFrames isEqualToArray:frames])
    {
      self.reservedFrames = frames;
      [self setNeedsLayout];
    }
  }
  [super updateConstraints];
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  if (self.layoutHandler)
  {
    self.layoutHandler();
  }
}

- (CGRect)usableBounds
{
  CGRect usable = self.safeAreaLayoutGuide.layoutFrame;
  for (NSValue* value in self.reservedFrames)
  {
    const CGRect reserved = CGRectIntersection(usable, value.CGRectValue);
    if (CGRectIsNull(reserved) || CGRectIsEmpty(reserved))
    {
      continue;
    }

    // Keep this rectangular game/control surface on the largest unobstructed
    // side. The native arrangement has already separated the two fold panels.
    const CGRect candidates[] = {
        CGRectMake(CGRectGetMinX(usable), CGRectGetMinY(usable),
                   CGRectGetMinX(reserved) - CGRectGetMinX(usable), usable.size.height),
        CGRectMake(CGRectGetMaxX(reserved), CGRectGetMinY(usable),
                   CGRectGetMaxX(usable) - CGRectGetMaxX(reserved), usable.size.height),
        CGRectMake(CGRectGetMinX(usable), CGRectGetMinY(usable), usable.size.width,
                   CGRectGetMinY(reserved) - CGRectGetMinY(usable)),
        CGRectMake(CGRectGetMinX(usable), CGRectGetMaxY(reserved), usable.size.width,
                   CGRectGetMaxY(usable) - CGRectGetMaxY(reserved))};
    CGRect best = CGRectZero;
    for (CGRect candidate : candidates)
    {
      if (candidate.size.width * candidate.size.height > best.size.width * best.size.height)
      {
        best = candidate;
      }
    }
    usable = best;
  }
  return usable;
}

@end

@interface EmulationiOSViewController ()
- (void)updateGameplayLayout;
@end

@implementation EmulationiOSViewController
{
  DOLEmulationVisibleTouchPad _visibleTouchPad;
  int _stateSlot;
  UIViewController* _gameplayContainer;
  UIViewController* _rendererController;
  UIViewController* _controlsController;
  DOLGameplayLayoutView* _rendererHost;
  DOLGameplayLayoutView* _controlsHost;
  UIView* _virtualControllerHost;
  BOOL _updatingGameplayLayout;
  CGRect _lastPointerRect;
  CGSize _lastPointerPadSize;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  [self installGameplayLayout];

  for (int i = 0; i < [self.touchPads count]; i++)
  {
    TCView* padView = self.touchPads[i];

    if (i + 1 == DOLEmulationVisibleTouchPadGameCube)
    {
      padView.port = 0;
    }
    else
    {
      // Wii pads are mapped to touchscreen device 4
      padView.port = 4;
    }
  }

  if (@available(iOS 15.0, *))
  {
    // Stupidity - iOS 15 now uses the scrollEdgeAppearance when the UINavigationBar is off screen.
    // https://developer.apple.com/forums/thread/682420
    UINavigationBar* bar = self.navigationController.navigationBar;
    bar.scrollEdgeAppearance = bar.standardAppearance;

    VirtualMFiControllerManager* virtualMfi = [VirtualMFiControllerManager shared];
    if (virtualMfi.shouldConnectController)
    {
      [virtualMfi connectControllerToView:_virtualControllerHost];
    }
  }

  _stateSlot = Config::GetBase(Config::MAIN_SELECTED_STATE_SLOT);

  self.pullDownButton.accessibilityLabel = NSLocalizedString(@"Show Emulation Controls", nil);
  self.navigationItem.leftBarButtonItem.accessibilityLabel =
      NSLocalizedString(@"Emulation Settings", nil);
}

- (void)installGameplayLayout
{
  // Hold the storyboard's weak outlets while moving their existing views.
  UIView* renderer = self.rendererView;
  UIButton* pullDown = self.pullDownButton;

  _rendererHost = [[DOLGameplayLayoutView alloc] initWithFrame:self.view.bounds];
  _controlsHost = [[DOLGameplayLayoutView alloc] initWithFrame:self.view.bounds];
  _rendererController = [[UIViewController alloc] init];
  _rendererController.view = _rendererHost;
  _controlsController = [[UIViewController alloc] init];
  _controlsController.view = _controlsHost;
  // On a flat display the controls are a full-size transparent overlay. The
  // arrangement constrains them to their own panel when a fold becomes active.
  _controlsController.preferredContentSize = self.view.bounds.size;

  if (@available(iOS 27.1, *))
  {
    UIArrangementViewController* arrangement = [[UIArrangementViewController alloc] init];
    // Primary is the foreground control surface; UIKit places it below the
    // game in tabletop use and beside the game when the fold runs vertically.
    [arrangement setViewController:_controlsController
                      forPlacement:UIArrangementViewControllerViewPlacementPrimary];
    [arrangement setViewController:_rendererController
                      forPlacement:UIArrangementViewControllerViewPlacementSecondary];
    [arrangement updateArrangement:[UIOverlayArrangement overlayArrangement]];
    _gameplayContainer = arrangement;
  }
  else
  {
    _gameplayContainer = [[UIViewController alloc] init];
    for (UIViewController* controller in @[ _rendererController, _controlsController ])
    {
      [_gameplayContainer addChildViewController:controller];
      controller.view.frame = _gameplayContainer.view.bounds;
      controller.view.autoresizingMask =
          UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
      [_gameplayContainer.view addSubview:controller.view];
      [controller didMoveToParentViewController:_gameplayContainer];
    }
  }

  [self addChildViewController:_gameplayContainer];
  _gameplayContainer.view.frame = self.view.bounds;
  _gameplayContainer.view.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [self.view addSubview:_gameplayContainer.view];
  [_gameplayContainer didMoveToParentViewController:self];

  [_rendererHost addSubview:renderer];
  for (TCView* pad in self.touchPads)
  {
    [_controlsHost addSubview:pad];
  }
  _virtualControllerHost = [[UIView alloc] initWithFrame:_controlsHost.bounds];
  [_controlsHost addSubview:_virtualControllerHost];
  // Only enable the host when it actually contains Apple's virtual controller.
  _virtualControllerHost.userInteractionEnabled =
      [VirtualMFiControllerManager shared].shouldConnectController;
  [_controlsHost addSubview:pullDown];

  __weak EmulationiOSViewController* weakSelf = self;
  void (^layoutHandler)(void) = ^{
    [weakSelf updateGameplayLayout];
  };
  _rendererHost.layoutHandler = layoutHandler;
  _controlsHost.layoutHandler = layoutHandler;
  [_rendererHost setNeedsUpdateConstraints];
  [_controlsHost setNeedsUpdateConstraints];
}

- (void)updateGameplayLayout
{
  if (_updatingGameplayLayout || !_rendererHost || !_controlsHost)
  {
    return;
  }
  _updatingGameplayLayout = YES;

  // The game is full-bleed content, not an interactive control. Applying the
  // controls' safe area and camera exclusion here removes an entire strip of
  // picture beside the camera on Duo, even while the navigation bar is hidden.
  // UIKit already assigns this host to the appropriate panel when folded.
  CGRect rendererFrame = _rendererHost.bounds;
  const CGRect controlsFrame = _controlsHost.usableBounds;
  const CGSize preferredControlsSize = _gameplayContainer.view.bounds.size;
  if (!CGSizeEqualToSize(_controlsController.preferredContentSize, preferredControlsSize))
  {
    _controlsController.preferredContentSize = preferredControlsSize;
  }
  BOOL separated = NO;
  if (@available(iOS 27.1, *))
  {
    UIArrangementViewController* arrangement = (UIArrangementViewController*)_gameplayContainer;
    UIArrangementViewState* state =
        [arrangement stateForPlacement:UIArrangementViewControllerViewPlacementPrimary];
    separated = state != nil && state.splitAxis != 0;
  }

  // A tall compact viewport retains the familiar game-above-controls layout.
  // Folded panels use all of the space assigned to them by UIKit instead.
  if (!separated && self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact &&
      rendererFrame.size.height > rendererFrame.size.width)
  {
    rendererFrame.size.height *= 0.5;
  }
  self.rendererView.frame = rendererFrame;
  for (TCView* pad in self.touchPads)
  {
    pad.frame = controlsFrame;
  }
  _virtualControllerHost.frame = controlsFrame;

  const CGFloat buttonSize = 44;
  self.pullDownButton.frame = CGRectMake(CGRectGetMinX(controlsFrame) + 8,
                                         CGRectGetMinY(controlsFrame) + 8, buttonSize, buttonSize);
  [_controlsHost bringSubviewToFront:self.pullDownButton];

  [[EmulationCoordinator shared] updateRenderSurface];
  const CGRect pointerRect = [self.rendererView convertRect:self.rendererView.bounds
                                                     toView:_controlsHost];
  if (!CGRectEqualToRect(pointerRect, _lastPointerRect) ||
      !CGSizeEqualToSize(controlsFrame.size, _lastPointerPadSize))
  {
    _lastPointerRect = pointerRect;
    _lastPointerPadSize = controlsFrame.size;
    [self updatePointerValuesOnWiiTouchPads];
  }
  _updatingGameplayLayout = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(receiveTitleChangedNotificationiOS)
                                               name:DOLHostTitleChangedNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(receiveRequestRenderWindowSizeNotificationiOS)
             name:DOLHostRequestRenderWindowSizeNotification
           object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(receiveEmulationEndNotificationiOS)
                                               name:DOLEmulationDidEndNotification
                                             object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];

  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:DOLHostTitleChangedNotification
                                                object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:DOLHostRequestRenderWindowSizeNotification
                                                object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:DOLEmulationDidEndNotification
                                                object:nil];
}

- (void)recreateMenu
{
  NSMutableArray<UIMenuElement*>* controllerActions = [[NSMutableArray alloc] init];

  NSMutableArray<UIMenuElement*>* visibleControllerActions = [[NSMutableArray alloc] init];

  bool wiimoteTouchPadAttached =
      [self isWiimoteTouchPadAttached] && Core::System::GetInstance().IsWii();
  bool gamecubeTouchPadAttached = [self isGameCubeTouchPadAttached];

  if (wiimoteTouchPadAttached)
  {
    UIAction* wiimoteAction = [UIAction actionWithTitle:DOLCoreLocalizedString(@"Wii Remote")
                                                  image:nil
                                             identifier:nil
                                                handler:^(UIAction*) {
                                                  [self updateVisibleTouchPadToWii];
                                                  [self recreateMenu];

                                                  [self updateNavigationBar:true];
                                                }];

    if (_visibleTouchPad == DOLEmulationVisibleTouchPadWiimote ||
        _visibleTouchPad == DOLEmulationVisibleTouchPadSidewaysWiimote ||
        _visibleTouchPad == DOLEmulationVisibleTouchPadClassic)
    {
      wiimoteAction.state = UIMenuElementStateOn;
    }
    else
    {
      wiimoteAction.state = UIMenuElementStateOff;
    }

    [visibleControllerActions addObject:wiimoteAction];
  }

  if (gamecubeTouchPadAttached)
  {
    UIAction* gamecubeAction =
        [UIAction actionWithTitle:DOLCoreLocalizedString(@"GameCube Controller")
                            image:nil
                       identifier:nil
                          handler:^(UIAction*) {
                            [self updateVisibleTouchPadToGameCube];
                            [self recreateMenu];

                            [self updateNavigationBar:true];
                          }];

    if (_visibleTouchPad == DOLEmulationVisibleTouchPadGameCube)
    {
      gamecubeAction.state = UIMenuElementStateOn;
    }
    else
    {
      gamecubeAction.state = UIMenuElementStateOff;
    }

    [visibleControllerActions addObject:gamecubeAction];
  }

  if (wiimoteTouchPadAttached || gamecubeTouchPadAttached)
  {
    UIAction* noneAction =
        [UIAction actionWithTitle:DOLCoreLocalizedString(@"Hide")
                            image:nil
                       identifier:nil
                          handler:^(UIAction*) {
                            [self updateVisibleTouchPadWithType:DOLEmulationVisibleTouchPadNone];
                            [self recreateMenu];

                            [self updateNavigationBar:true];
                          }];

    if (_visibleTouchPad == DOLEmulationVisibleTouchPadNone)
    {
      noneAction.state = UIMenuElementStateOn;
    }
    else
    {
      noneAction.state = UIMenuElementStateOff;
    }

    [visibleControllerActions addObject:noneAction];
  }

  UIMenu* visibleControllerMenu = [UIMenu menuWithTitle:@"Touch Controller"
                                                  image:[UIImage systemImageNamed:@"gamecontroller"]
                                             identifier:nil
                                                options:0
                                               children:visibleControllerActions];
  [controllerActions addObject:visibleControllerMenu];

  if (wiimoteTouchPadAttached)
  {
    TCWiiTouchIRMode irMode = (TCWiiTouchIRMode)Config::Get(Config::MAIN_TOUCH_PAD_IR_MODE);

    UIMenu* menu =
        [UIMenu menuWithTitle:@"Touch IR Pointer"
                        image:[UIImage systemImageNamed:@"hand.point.up.left"]
                   identifier:nil
                      options:0
                     children:@[
                       [UIAction actionWithTitle:@"Disabled"
                                           image:nil
                                      identifier:nil
                                         handler:^(UIAction*) {
                                           Config::SetBaseOrCurrent(Config::MAIN_TOUCH_PAD_IR_MODE,
                                                                    TCWiiTouchIRModeNone);

                                           [self updatePointerValuesOnWiiTouchPads];
                                           [self recreateMenu];

                                           [self updateNavigationBar:true];
                                         }],
                       [UIAction actionWithTitle:@"Follow"
                                           image:nil
                                      identifier:nil
                                         handler:^(UIAction*) {
                                           Config::SetBaseOrCurrent(Config::MAIN_TOUCH_PAD_IR_MODE,
                                                                    TCWiiTouchIRModeFollow);

                                           [self updatePointerValuesOnWiiTouchPads];
                                           [self recreateMenu];

                                           [self updateNavigationBar:true];
                                         }],
                       [UIAction actionWithTitle:@"Drag"
                                           image:nil
                                      identifier:nil
                                         handler:^(UIAction*) {
                                           Config::SetBaseOrCurrent(Config::MAIN_TOUCH_PAD_IR_MODE,
                                                                    TCWiiTouchIRModeDrag);

                                           [self updatePointerValuesOnWiiTouchPads];
                                           [self recreateMenu];

                                           [self updateNavigationBar:true];
                                         }]
                     ]];

    UIAction* selectedAction = (UIAction*)menu.children[(int)irMode];
    selectedAction.state = UIMenuElementStateOn;

    [controllerActions addObject:menu];
  }

  NSMutableArray<UIMenuElement*>* stateSlotActions = [[NSMutableArray alloc] init];

  for (int i = 1; i <= State::NUM_STATES; i++)
  {
    [stateSlotActions
        addObject:[UIAction actionWithTitle:[NSString stringWithFormat:@"Slot %d", i]
                                      image:nil
                                 identifier:nil
                                    handler:^(UIAction* action) {
                                      self->_stateSlot = i;
                                      Config::SetBase(Config::MAIN_SELECTED_STATE_SLOT, i);

                                      [self recreateMenu];
                                    }]];
  }

  UIAction* selectedSlotElement = (UIAction*)[stateSlotActions
      objectAtIndex:Config::GetBase(Config::MAIN_SELECTED_STATE_SLOT) - 1];
  selectedSlotElement.state = UIMenuElementStateOn;

  NSMutableArray<UIMenuElement*>* menuItems = [[NSMutableArray alloc] init];
  [menuItems addObject:[UIMenu menuWithTitle:DOLCoreLocalizedString(@"Controllers")
                                       image:nil
                                  identifier:nil
                                     options:UIMenuOptionsDisplayInline
                                    children:controllerActions]];
  [menuItems
      addObject:[UIMenu
                    menuWithTitle:DOLCoreLocalizedString(@"Save State")
                            image:nil
                       identifier:nil
                          options:UIMenuOptionsDisplayInline
                         children:@[
                           [UIMenu menuWithTitle:DOLCoreLocalizedString(@"Select State Slot")
                                           image:nil
                                      identifier:nil
                                         options:0
                                        children:stateSlotActions],
                           [UIAction
                               actionWithTitle:DOLCoreLocalizedString(@"Load State")
                                         image:[UIImage systemImageNamed:@"tray.and.arrow.down"]
                                    identifier:nil
                                       handler:^(UIAction*) {
                                         DOLHostQueueRunAsync(^{
                                           State::Load(Core::System::GetInstance(),
                                                       self->_stateSlot);
                                         });

                                         [self updateNavigationBar:true];
                                       }],
                           [UIAction actionWithTitle:DOLCoreLocalizedString(@"Save State")
                                               image:[UIImage systemImageNamed:@"tray.and.arrow.up"]
                                          identifier:nil
                                             handler:^(UIAction*) {
                                               DOLHostQueueRunAsync(^{
                                                 State::Save(Core::System::GetInstance(),
                                                             self->_stateSlot);
                                               });

                                               [self updateNavigationBar:true];
                                             }]
                         ]]];

  if ([self emulateSkylanderPortal] && Core::System::GetInstance().IsWii())
  {
    [menuItems
        addObject:
            [UIMenu
                menuWithTitle:DOLCoreLocalizedString(@"Tools")
                        image:nil
                   identifier:nil
                      options:UIMenuOptionsDisplayInline
                     children:@[
                       [UIAction
                           actionWithTitle:DOLCoreLocalizedString(@"Skylanders Portal")
                                     image:[UIImage systemImageNamed:@"externalDrive"]
                                identifier:nil
                                   handler:^(UIAction*) {
                                     UIAlertController* alert = [UIAlertController
                                         alertControllerWithTitle:@"Skylanders Manager"
                                                          message:nil
                                                   preferredStyle:UIAlertControllerStyleAlert];
                                     UIAlertAction* loadAction = [UIAlertAction
                                         actionWithTitle:@"Load"
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction* action) {
                                                   NSArray<UTType*>* types =
                                                       @[ [UTType exportedTypeWithIdentifier:
                                                                      @"me.oatmealdome.dolphinios."
                                                                      @"skylander-dumps"] ];
                                                   UIDocumentPickerViewController*
                                                       pickerController =
                                                           [[UIDocumentPickerViewController alloc]
                                                               initForOpeningContentTypes:types];
                                                   pickerController.delegate = self;
                                                   pickerController.modalPresentationStyle =
                                                       UIModalPresentationPageSheet;
                                                   pickerController.allowsMultipleSelection = false;

                                                   [self presentViewController:pickerController
                                                                      animated:true
                                                                    completion:nil];
                                                 }];
                                     UIAlertAction* clearAction = [UIAlertAction
                                         actionWithTitle:@"Clear"
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction* action) {
                                                   auto& system = Core::System::GetInstance();
                                                   if (self.skylanderSlot)
                                                   {
                                                     bool removed = system.GetSkylanderPortal()
                                                                        .RemoveSkylander(
                                                                            self.skylanderSlot - 1);
                                                     if (removed && self.skylanderSlot != 0)
                                                     {
                                                       self.skylanderSlot--;
                                                     }
                                                   }
                                                 }];
                                     UIAlertAction* clearAllAction = [UIAlertAction
                                         actionWithTitle:@"Clear All"
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction* action) {
                                                   auto& system = Core::System::GetInstance();
                                                   if (self.skylanderSlot)
                                                   {
                                                     for (int i = 0; i < 16; i++)
                                                     {
                                                       system.GetSkylanderPortal().RemoveSkylander(
                                                           i);
                                                     }
                                                   }
                                                   self.skylanderSlot = 0;
                                                 }];
                                     [alert addAction:loadAction];
                                     [alert addAction:clearAction];
                                     [alert addAction:clearAllAction];
                                     [self presentViewController:alert animated:YES completion:nil];
                                   }]
                     ]]];
  }

  self.navigationItem.leftBarButtonItem.menu = [UIMenu menuWithChildren:menuItems];
}

- (void)viewDidLayoutSubviews
{
  [super viewDidLayoutSubviews];
  [self updateGameplayLayout];
  UIWindowScene* windowScene = self.view.window.windowScene;
  if (windowScene != nil)
  {
    [[TCDeviceMotion shared] setInterfaceOrientation:windowScene.interfaceOrientation];
  }
}

- (void)viewSafeAreaInsetsDidChange
{
  [super viewSafeAreaInsetsDidChange];
  [_rendererHost setNeedsLayout];
  [_controlsHost setNeedsLayout];
}

- (BOOL)prefersHomeIndicatorAutoHidden
{
  return true;
}

- (void)receiveTitleChangedNotificationiOS
{
  dispatch_async(dispatch_get_main_queue(), ^{
    if (Core::System::GetInstance().IsWii())
    {
      [self updateVisibleTouchPadToWii];
    }
    else
    {
      [self updateVisibleTouchPadToGameCube];
    }

    [self recreateMenu];
  });
}

- (void)receiveRequestRenderWindowSizeNotificationiOS
{
  dispatch_async(dispatch_get_main_queue(), ^{
    if (Core::System::GetInstance().IsWii())
    {
      [self updatePointerValuesOnWiiTouchPads];
    }
  });
}

- (bool)isWiimoteTouchPadAttached
{
  if (Config::Get(Config::GetInfoForWiimoteSource(0)) != WiimoteSource::Emulated)
  {
    // Nothing is plugged in to this port.
    return false;
  }

  const auto wiimote = static_cast<WiimoteEmu::Wiimote*>(Wiimote::GetConfig()->GetController(0));

  if (wiimote->GetDefaultDevice().source != "iOS")
  {
    // A real controller is mapped to this port.
    return false;
  }

  return true;
}

- (bool)emulateSkylanderPortal
{
  return Config::Get(Config::MAIN_EMULATE_SKYLANDER_PORTAL);
}

- (bool)isGameCubeTouchPadAttached
{
  if (Config::Get(Config::GetInfoForSIDevice(0)) == SerialInterface::SIDEVICE_NONE)
  {
    // Nothing is plugged in to this port.
    return false;
  }

  const auto device = Pad::GetConfig()->GetController(0);

  if (device->GetDefaultDevice().source != "iOS")
  {
    // A real controller is mapped to this port.
    return false;
  }

  return true;
}

- (void)updateVisibleTouchPadToWii
{
  if (![self isWiimoteTouchPadAttached])
  {
    // Fallback to GameCube in case port 1 is bound to the touchscreen.
    [self updateVisibleTouchPadToGameCube];

    return;
  }

  DOLEmulationVisibleTouchPad targetTouchPad;

  const auto wiimote = static_cast<WiimoteEmu::Wiimote*>(Wiimote::GetConfig()->GetController(0));

  if (wiimote->GetActiveExtensionNumber() == WiimoteEmu::ExtensionNumber::CLASSIC)
  {
    targetTouchPad = DOLEmulationVisibleTouchPadClassic;
  }
  else if (wiimote->IsSideways())
  {
    targetTouchPad = DOLEmulationVisibleTouchPadSidewaysWiimote;
  }
  else
  {
    targetTouchPad = DOLEmulationVisibleTouchPadWiimote;
  }

  [self updateVisibleTouchPadWithType:targetTouchPad];

  [self updatePointerValuesOnWiiTouchPads];
}

- (void)updateVisibleTouchPadToGameCube
{
  if (![self isGameCubeTouchPadAttached])
  {
    return;
  }

  [self updateVisibleTouchPadWithType:DOLEmulationVisibleTouchPadGameCube];
}

- (void)updateVisibleTouchPadWithType:(DOLEmulationVisibleTouchPad)touchPad
{
  if (_visibleTouchPad == touchPad)
  {
    return;
  }

  TCDeviceMotion* motion = [TCDeviceMotion shared];

  if (touchPad == DOLEmulationVisibleTouchPadWiimote ||
      touchPad == DOLEmulationVisibleTouchPadSidewaysWiimote ||
      touchPad == DOLEmulationVisibleTouchPadClassic)
  {
    UIWindowScene* windowScene = self.view.window.windowScene;
    if (windowScene != nil)
    {
      [motion setInterfaceOrientation:windowScene.interfaceOrientation];
    }
    [motion setMotionEnabled:true];
    [motion setPort:4];  // Touchscreen device 4 is used for the Wiimote
  }
  else
  {
    [motion setMotionEnabled:false];
  }

  NSInteger targetIdx = touchPad - 1;

  for (int i = 0; i < [self.touchPads count]; i++)
  {
    TCView* padView = self.touchPads[i];
    padView.userInteractionEnabled = i == targetIdx;
  }

  const float targetOpacity = Config::Get(Config::MAIN_TOUCH_PAD_OPACITY);

  [UIView animateWithDuration:0.5f
                   animations:^{
                     for (int i = 0; i < [self.touchPads count]; i++)
                     {
                       TCView* padView = self.touchPads[i];
                       padView.alpha = i == targetIdx ? targetOpacity : 0.0f;
                     }
                   }];

  _visibleTouchPad = touchPad;
}

- (void)updatePointerValuesOnWiiTouchPads
{
  if (!g_presenter)
  {
    return;
  }

  TCWiiTouchIRMode irMode = TCWiiTouchIRModeNone;

  if ([self isWiimoteTouchPadAttached])
  {
    irMode = (TCWiiTouchIRMode)Config::Get(Config::MAIN_TOUCH_PAD_IR_MODE);

    ControllerEmu::ControlGroup* group =
        Wiimote::GetWiimoteGroup(0, WiimoteEmu::WiimoteGroup::IMUPoint);
    group->enabled.SetValue(irMode == TCWiiTouchIRModeNone);
  }

  for (int i = 0; i < [self.touchPads count]; i++)
  {
    TCView* padView = self.touchPads[i];

    if ([padView isKindOfClass:[TCWiiPad class]])
    {
      TCWiiPad* wiiPadView = (TCWiiPad*)padView;

      [wiiPadView setTouchIRMode:irMode];
      [wiiPadView resetPointer];
      // In a separated arrangement the controls become a touchpad for the
      // display above/beside them. In an overlay, preserve direct screen mapping.
      CGRect pointerRect = [self.rendererView convertRect:self.rendererView.bounds
                                                   toView:wiiPadView];
      if (!CGRectIntersectsRect(pointerRect, wiiPadView.bounds))
      {
        pointerRect = wiiPadView.bounds;
      }
      [wiiPadView recalculatePointerValuesWithNew_rect:pointerRect
                                           game_aspect:g_presenter->CalculateDrawAspectRatio()];
    }
  }
}

- (IBAction)pullDownPressed:(id)sender
{
  [self updateNavigationBar:false];
}

- (void)updateNavigationBar:(bool)hidden
{
  [super updateNavigationBar:hidden];
  self.pullDownButton.hidden = !hidden;
  [self updateGameplayLayout];
}

- (void)receiveEmulationEndNotificationiOS
{
  if (@available(iOS 15.0, *))
  {
    dispatch_async(dispatch_get_main_queue(), ^{
      [[VirtualMFiControllerManager shared] disconnectController];
    });
  }

  [[TCDeviceMotion shared] setMotionEnabled:false];
}

- (void)documentPicker:(UIDocumentPickerViewController*)controller
    didPickDocumentsAtURLs:(NSArray<NSURL*>*)urls
{
  NSString* sourcePath = [urls[0] path];
  std::string path = std::string([sourcePath UTF8String]);
  File::IOFile sky_file(path, "r+b");
  if (!sky_file)
  {
    UIAlertController* alert =
        [UIAlertController alertControllerWithTitle:@"Failed to Open Skylander File!"
                                            message:nil
                                     preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:nil];
    return;
  }
  std::array<u8, 0x40 * 0x10> file_data;
  if (!sky_file.ReadBytes(file_data.data(), file_data.size()))
  {
    UIAlertController* alert =
        [UIAlertController alertControllerWithTitle:@"Failed to Read Skylander File!"
                                            message:nil
                                     preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:nil];
    return;
  }
  auto& system = Core::System::GetInstance();
  std::pair<u16, u16> id_var = system.GetSkylanderPortal().CalculateIDs(file_data);
  u8 portal_slot = system.GetSkylanderPortal().LoadSkylander(
      std::make_unique<IOS::HLE::USB::SkylanderFigure>(std::move(sky_file)));
  if (portal_slot == 0xFF)
  {
    UIAlertController* alert =
        [UIAlertController alertControllerWithTitle:@"Failed to Load Skylander File!"
                                            message:nil
                                     preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:nil];
    return;
  }
  self.skylanderSlot = portal_slot + 1;
}

@end
