// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "EmulationiOSViewController.h"

#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

#import "Common/IOFile.h"

#import "Core/ConfigManager.h"
#import "Core/Config/iOSSettings.h"
#import "Core/Config/MainSettings.h"
#import "Core/Config/WiimoteSettings.h"
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

@interface EmulationiOSViewController ()

@end

@implementation EmulationiOSViewController {
  DOLEmulationVisibleTouchPad _visibleTouchPad;
  int _stateSlot;
  NSTimer* _pullDownHideTimer;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  for (int i = 0; i < [self.touchPads count]; i++) {
    TCView* padView = self.touchPads[i];

    if (i + 1 == DOLEmulationVisibleTouchPadGameCube) {
      padView.port = 0;
    } else {
      // Wii pads are mapped to touchscreen device 4
      padView.port = 4;
    }
  }

  if (@available(iOS 15.0, *)) {
    // Stupidity - iOS 15 now uses the scrollEdgeAppearance when the UINavigationBar is off screen.
    // https://developer.apple.com/forums/thread/682420
    UINavigationBar* bar = self.navigationController.navigationBar;
    bar.scrollEdgeAppearance = bar.standardAppearance;

    VirtualMFiControllerManager* virtualMfi = [VirtualMFiControllerManager shared];
    if (virtualMfi.shouldConnectController) {
      [virtualMfi connectControllerToView:self.view];
    }
  }

  _stateSlot = Config::GetBase(Config::MAIN_SELECTED_STATE_SLOT);

  // On iPadOS 26, the pull down button in the upper left can be blocked by window controls.
  if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
    self.pullDownLeftConstraint.active = false;
    self.pullDownCenterConstraint.active = true;
  }

  // Add tap gesture to show the pull-down button when it's hidden
  UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(screenTapped:)];
  tapGesture.cancelsTouchesInView = NO;
  [self.view addGestureRecognizer:tapGesture];

  // Start the auto-hide timer for the pull-down button
  [self resetPullDownHideTimer];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveTitleChangedNotificationiOS) name:DOLHostTitleChangedNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveRequestRenderWindowSizeNotificationiOS) name:DOLHostRequestRenderWindowSizeNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveEmulationEndNotificationiOS) name:DOLEmulationDidEndNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];

  [self invalidatePullDownHideTimer];

  [[NSNotificationCenter defaultCenter] removeObserver:self name:DOLHostTitleChangedNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:DOLHostRequestRenderWindowSizeNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:DOLEmulationDidEndNotification object:nil];
}

- (void)recreateMenu {
  NSMutableArray<UIMenuElement*>* controllerActions = [[NSMutableArray alloc] init];

  NSMutableArray<UIMenuElement*>* visibleControllerActions = [[NSMutableArray alloc] init];

  bool wiimoteTouchPadAttached = [self isWiimoteTouchPadAttached] && Core::System::GetInstance().IsWii();
  bool gamecubeTouchPadAttached = [self isGameCubeTouchPadAttached];

  if (wiimoteTouchPadAttached) {
    UIAction* wiimoteAction = [UIAction actionWithTitle:DOLCoreLocalizedString(@"Wii Remote") image:nil identifier:nil handler:^(UIAction*) {
      [self updateVisibleTouchPadToWii];
      [self recreateMenu];

      [self hideNavigationBarAndRestartTimer];
    }];

    if (_visibleTouchPad == DOLEmulationVisibleTouchPadWiimote ||
        _visibleTouchPad == DOLEmulationVisibleTouchPadSidewaysWiimote ||
        _visibleTouchPad == DOLEmulationVisibleTouchPadClassic) {
      wiimoteAction.state = UIMenuElementStateOn;
    } else {
      wiimoteAction.state = UIMenuElementStateOff;
    }

    [visibleControllerActions addObject:wiimoteAction];
  }

  if (gamecubeTouchPadAttached) {
    UIAction* gamecubeAction = [UIAction actionWithTitle:DOLCoreLocalizedString(@"GameCube Controller") image:nil identifier:nil handler:^(UIAction*) {
      [self updateVisibleTouchPadToGameCube];
      [self recreateMenu];

      [self hideNavigationBarAndRestartTimer];
    }];

    if (_visibleTouchPad == DOLEmulationVisibleTouchPadGameCube) {
      gamecubeAction.state = UIMenuElementStateOn;
    } else {
      gamecubeAction.state = UIMenuElementStateOff;
    }

    [visibleControllerActions addObject:gamecubeAction];
  }

  if (wiimoteTouchPadAttached || gamecubeTouchPadAttached) {
    UIAction* noneAction = [UIAction actionWithTitle:DOLCoreLocalizedString(@"Hide") image:nil identifier:nil handler:^(UIAction*) {
      [self updateVisibleTouchPadWithType:DOLEmulationVisibleTouchPadNone];
      [self recreateMenu];

      [self hideNavigationBarAndRestartTimer];
    }];

    if (_visibleTouchPad == DOLEmulationVisibleTouchPadNone) {
      noneAction.state = UIMenuElementStateOn;
    } else {
      noneAction.state = UIMenuElementStateOff;
    }

    [visibleControllerActions addObject:noneAction];
  }

  UIMenu* visibleControllerMenu = [UIMenu menuWithTitle:@"Touch Controller" image:[UIImage systemImageNamed:@"gamecontroller"] identifier:nil options:0 children:visibleControllerActions];
  [controllerActions addObject:visibleControllerMenu];

  if (wiimoteTouchPadAttached) {
    TCWiiTouchIRMode irMode = (TCWiiTouchIRMode)Config::Get(Config::MAIN_TOUCH_PAD_IR_MODE);

    UIMenu* menu = [UIMenu menuWithTitle:@"Touch IR Pointer" image:[UIImage systemImageNamed:@"hand.point.up.left"] identifier:nil options:0 children:@[
      [UIAction actionWithTitle:@"Disabled" image:nil identifier:nil handler:^(UIAction*) {
        Config::SetBaseOrCurrent(Config::MAIN_TOUCH_PAD_IR_MODE, TCWiiTouchIRModeNone);

        [self updatePointerValuesOnWiiTouchPads];
        [self recreateMenu];

        [self hideNavigationBarAndRestartTimer];
      }],
      [UIAction actionWithTitle:@"Follow" image:nil identifier:nil handler:^(UIAction*) {
        Config::SetBaseOrCurrent(Config::MAIN_TOUCH_PAD_IR_MODE, TCWiiTouchIRModeFollow);

        [self updatePointerValuesOnWiiTouchPads];
        [self recreateMenu];

        [self hideNavigationBarAndRestartTimer];
      }],
      [UIAction actionWithTitle:@"Drag" image:nil identifier:nil handler:^(UIAction*) {
        Config::SetBaseOrCurrent(Config::MAIN_TOUCH_PAD_IR_MODE, TCWiiTouchIRModeDrag);

        [self updatePointerValuesOnWiiTouchPads];
        [self recreateMenu];

        [self hideNavigationBarAndRestartTimer];
      }]
    ]];

    UIAction* selectedAction = (UIAction*)menu.children[(int)irMode];
    selectedAction.state = UIMenuElementStateOn;

    [controllerActions addObject:menu];
  }

  NSMutableArray<UIMenuElement*>* stateSlotActions = [[NSMutableArray alloc] init];

  for (int i = 1; i <= State::NUM_STATES; i++) {
    [stateSlotActions addObject:[UIAction actionWithTitle:[NSString stringWithFormat:@"Slot %d", i] image:nil identifier:nil handler:^(UIAction* action) {
      self->_stateSlot = i;
      Config::SetBase(Config::MAIN_SELECTED_STATE_SLOT, i);

      [self recreateMenu];
    }]];
  }

  UIAction* selectedSlotElement = (UIAction*)[stateSlotActions objectAtIndex:Config::GetBase(Config::MAIN_SELECTED_STATE_SLOT) - 1];
  selectedSlotElement.state = UIMenuElementStateOn;
  
  NSMutableArray<UIMenuElement*>* menuItems = [[NSMutableArray alloc] init];
  [menuItems addObject:[UIMenu menuWithTitle:DOLCoreLocalizedString(@"Controllers") image:nil identifier:nil options:UIMenuOptionsDisplayInline children:controllerActions]];
  [menuItems addObject:[UIMenu menuWithTitle:DOLCoreLocalizedString(@"Save State") image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[
    [UIMenu menuWithTitle:DOLCoreLocalizedString(@"Select State Slot") image:nil identifier:nil options:0 children:stateSlotActions],
    [UIAction actionWithTitle:DOLCoreLocalizedString(@"Load State") image:[UIImage systemImageNamed:@"tray.and.arrow.down"] identifier:nil handler:^(UIAction*) {
      DOLHostQueueRunAsync(^{
        State::Load(Core::System::GetInstance(), self->_stateSlot);
      });

      [self hideNavigationBarAndRestartTimer];
    }],
    [UIAction actionWithTitle:DOLCoreLocalizedString(@"Save State") image:[UIImage systemImageNamed:@"tray.and.arrow.up"] identifier:nil handler:^(UIAction*) {
      DOLHostQueueRunAsync(^{
        State::Save(Core::System::GetInstance(), self->_stateSlot);
      });

      [self hideNavigationBarAndRestartTimer];
    }]
  ]]];
  
  if ([self emulateSkylanderPortal] && Core::System::GetInstance().IsWii()) {
    [menuItems addObject:[UIMenu menuWithTitle:DOLCoreLocalizedString(@"Tools") image:nil identifier:nil options:UIMenuOptionsDisplayInline
                 children:@[
        [UIAction actionWithTitle:DOLCoreLocalizedString(@"Skylanders Portal") image:[UIImage systemImageNamed:@"externalDrive"] identifier:nil handler:^(UIAction*) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Skylanders Manager"
                                       message:nil
                                       preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* loadAction = [UIAlertAction actionWithTitle:@"Load" style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction* action) {
            NSArray<UTType*>* types = @[
                [UTType exportedTypeWithIdentifier:@"me.oatmealdome.dolphinios.skylander-dumps"]
              ];
            UIDocumentPickerViewController* pickerController = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:types];
            pickerController.delegate = self;
            pickerController.modalPresentationStyle = UIModalPresentationPageSheet;
            pickerController.allowsMultipleSelection = false;

            [self presentViewController:pickerController animated:true completion:nil];

        }];
        UIAlertAction* clearAction = [UIAlertAction actionWithTitle:@"Clear" style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction* action) {
            auto& system = Core::System::GetInstance();
            if (self.skylanderSlot) {
              bool removed = system.GetSkylanderPortal().RemoveSkylander(self.skylanderSlot - 1);
              if (removed && self.skylanderSlot != 0) {
                  self.skylanderSlot--;
              }
            }
        }];
        UIAlertAction* clearAllAction = [UIAlertAction actionWithTitle:@"Clear All" style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction* action) {
            auto& system = Core::System::GetInstance();
            if (self.skylanderSlot) {
              for (int i = 0; i < 16; i++) {
                  system.GetSkylanderPortal().RemoveSkylander(i);
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

  NSInteger currentOrientationLock = [[NSUserDefaults standardUserDefaults] integerForKey:@"DOLOrientationLock"];

  UIAction* orientationAutoAction = [UIAction actionWithTitle:@"Auto" image:[UIImage systemImageNamed:@"rotate.3d"] identifier:nil handler:^(UIAction*) {
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"DOLOrientationLock"];
    [self applyOrientationLock];
    [self recreateMenu];
    [self hideNavigationBarAndRestartTimer];
  }];
  orientationAutoAction.state = currentOrientationLock == 0 ? UIMenuElementStateOn : UIMenuElementStateOff;

  UIAction* orientationPortraitAction = [UIAction actionWithTitle:@"Portrait" image:[UIImage systemImageNamed:@"rectangle.portrait"] identifier:nil handler:^(UIAction*) {
    [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"DOLOrientationLock"];
    [self applyOrientationLock];
    [self recreateMenu];
    [self hideNavigationBarAndRestartTimer];
  }];
  orientationPortraitAction.state = currentOrientationLock == 1 ? UIMenuElementStateOn : UIMenuElementStateOff;

  UIAction* orientationLandscapeAction = [UIAction actionWithTitle:@"Landscape" image:[UIImage systemImageNamed:@"rectangle"] identifier:nil handler:^(UIAction*) {
    [[NSUserDefaults standardUserDefaults] setInteger:2 forKey:@"DOLOrientationLock"];
    [self applyOrientationLock];
    [self recreateMenu];
    [self hideNavigationBarAndRestartTimer];
  }];
  orientationLandscapeAction.state = currentOrientationLock == 2 ? UIMenuElementStateOn : UIMenuElementStateOff;

  UIMenu* orientationLockMenu = [UIMenu menuWithTitle:@"Orientation Lock" image:[UIImage systemImageNamed:@"lock.rotation"] identifier:nil options:0 children:@[orientationAutoAction, orientationPortraitAction, orientationLandscapeAction]];

  [menuItems addObject:[UIMenu menuWithTitle:@"Display" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[orientationLockMenu]]];

  // Settings action - opens the full Settings screen during emulation
  UIAction* settingsAction = [UIAction actionWithTitle:@"Settings" image:[UIImage systemImageNamed:@"gearshape"] identifier:nil handler:^(UIAction*) {
    UIStoryboard* settingsStoryboard = [UIStoryboard storyboardWithName:@"SettingsRoot" bundle:nil];
    UIViewController* settingsVC = [settingsStoryboard instantiateInitialViewController];
    settingsVC.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:settingsVC animated:YES completion:nil];
  }];
  [menuItems addObject:[UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[settingsAction]]];

  self.navigationItem.leftBarButtonItem.menu = [UIMenu menuWithChildren:menuItems];
}

- (void)viewDidLayoutSubviews {
  if (g_presenter) {
    g_presenter->ResizeSurface();
  }

  [[TCDeviceMotion shared] statusBarOrientationChanged];

  [self updatePointerValuesOnWiiTouchPads];
}

- (BOOL)prefersHomeIndicatorAutoHidden {
  return true;
}

- (void)receiveTitleChangedNotificationiOS {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (Core::System::GetInstance().IsWii()) {
      [self updateVisibleTouchPadToWii];
    } else {
      [self updateVisibleTouchPadToGameCube];
    }

    [self recreateMenu];
  });
}

- (void)receiveRequestRenderWindowSizeNotificationiOS {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (Core::System::GetInstance().IsWii()) {
      [self updatePointerValuesOnWiiTouchPads];
    }
  });
}

- (bool)isWiimoteTouchPadAttached {
  if (Config::Get(Config::GetInfoForWiimoteSource(0)) != WiimoteSource::Emulated) {
    // Nothing is plugged in to this port.
    return false;
  }

  const auto wiimote = static_cast<WiimoteEmu::Wiimote*>(Wiimote::GetConfig()->GetController(0));

  if (wiimote->GetDefaultDevice().source != "iOS") {
    // A real controller is mapped to this port.
    return false;
  }

  return true;
}

- (bool)emulateSkylanderPortal {
  return Config::Get(Config::MAIN_EMULATE_SKYLANDER_PORTAL);
}

- (bool)isGameCubeTouchPadAttached {
  if (Config::Get(Config::GetInfoForSIDevice(0)) == SerialInterface::SIDEVICE_NONE) {
    // Nothing is plugged in to this port.
    return false;
  }

  const auto device = Pad::GetConfig()->GetController(0);

  if (device->GetDefaultDevice().source != "iOS") {
    // A real controller is mapped to this port.
    return false;
  }

  return true;
}

- (void)updateVisibleTouchPadToWii {
  if (![self isWiimoteTouchPadAttached]) {
    // Fallback to GameCube in case port 1 is bound to the touchscreen.
    [self updateVisibleTouchPadToGameCube];

    return;
  }

  DOLEmulationVisibleTouchPad targetTouchPad;

  const auto wiimote = static_cast<WiimoteEmu::Wiimote*>(Wiimote::GetConfig()->GetController(0));

  if (wiimote->GetActiveExtensionNumber() == WiimoteEmu::ExtensionNumber::CLASSIC) {
    targetTouchPad = DOLEmulationVisibleTouchPadClassic;
  } else if (wiimote->IsSideways()) {
    targetTouchPad = DOLEmulationVisibleTouchPadSidewaysWiimote;
  } else {
    targetTouchPad = DOLEmulationVisibleTouchPadWiimote;
  }

  [self updateVisibleTouchPadWithType:targetTouchPad];

  [self updatePointerValuesOnWiiTouchPads];
}

- (void)updateVisibleTouchPadToGameCube {
  if (![self isGameCubeTouchPadAttached]) {
    return;
  }

  [self updateVisibleTouchPadWithType:DOLEmulationVisibleTouchPadGameCube];
}

- (void)updateVisibleTouchPadWithType:(DOLEmulationVisibleTouchPad)touchPad {
  if (_visibleTouchPad == touchPad) {
    return;
  }

  TCDeviceMotion* motion = [TCDeviceMotion shared];

  if (touchPad == DOLEmulationVisibleTouchPadWiimote || touchPad == DOLEmulationVisibleTouchPadSidewaysWiimote || touchPad == DOLEmulationVisibleTouchPadClassic) {
    [motion setMotionEnabled:true];
    [motion setPort:4]; // Touchscreen device 4 is used for the Wiimote
  } else {
    [motion setMotionEnabled:false];
  }

  NSInteger targetIdx = touchPad - 1;

  for (int i = 0; i < [self.touchPads count]; i++) {
    TCView* padView = self.touchPads[i];
    padView.userInteractionEnabled = i == targetIdx;
  }

  const float targetOpacity = Config::Get(Config::MAIN_TOUCH_PAD_OPACITY);

  [UIView animateWithDuration:0.5f animations:^{
    for (int i = 0; i < [self.touchPads count]; i++) {
      TCView* padView = self.touchPads[i];
      padView.alpha = i == targetIdx ? targetOpacity : 0.0f;
    }
  }];

  _visibleTouchPad = touchPad;
}

- (void)updatePointerValuesOnWiiTouchPads {
  if (!g_presenter) {
    return;
  }

  TCWiiTouchIRMode irMode = TCWiiTouchIRModeNone;

  if ([self isWiimoteTouchPadAttached]) {
    irMode = (TCWiiTouchIRMode)Config::Get(Config::MAIN_TOUCH_PAD_IR_MODE);

    ControllerEmu::ControlGroup* group = Wiimote::GetWiimoteGroup(0, WiimoteEmu::WiimoteGroup::IMUPoint);
    group->enabled.SetValue(irMode == TCWiiTouchIRModeNone);
  }

  for (int i = 0; i < [self.touchPads count]; i++) {
    TCView* padView = self.touchPads[i];

    if ([padView isKindOfClass:[TCWiiPad class]]) {
      TCWiiPad* wiiPadView = (TCWiiPad*)padView;

      [wiiPadView setTouchIRMode:irMode];
      [wiiPadView resetPointer];
      [wiiPadView recalculatePointerValuesWithNew_rect:self.rendererView.bounds game_aspect:g_presenter->CalculateDrawAspectRatio()];
    }
  }
}

- (void)applyOrientationLock {
  if (@available(iOS 16.0, *)) {
    [self setNeedsUpdateOfSupportedInterfaceOrientations];
  } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [UIViewController attemptRotationToDeviceOrientation];
#pragma clang diagnostic pop
  }
}

- (IBAction)pullDownPressed:(id)sender {
  [self invalidatePullDownHideTimer];
  [self updateNavigationBar:false];
}

- (void)resetPullDownHideTimer {
  [self invalidatePullDownHideTimer];
  _pullDownHideTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(hidePullDownButton) userInfo:nil repeats:NO];
}

- (void)invalidatePullDownHideTimer {
  [_pullDownHideTimer invalidate];
  _pullDownHideTimer = nil;
}

- (void)hidePullDownButton {
  [UIView animateWithDuration:0.3 animations:^{
    self.pullDownButton.alpha = 0.0;
  }];
}

- (void)screenTapped:(UITapGestureRecognizer*)gesture {
  if (self.pullDownButton.alpha == 0.0) {
    [UIView animateWithDuration:0.3 animations:^{
      self.pullDownButton.alpha = 1.0;
    }];
    [self resetPullDownHideTimer];
  }
}

- (void)hideNavigationBarAndRestartTimer {
  [self.navigationController setNavigationBarHidden:true animated:true];
  self.pullDownButton.alpha = 1.0;
  [self resetPullDownHideTimer];
}

- (void)receiveEmulationEndNotificationiOS {
  if (@available(iOS 15.0, *)) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [[VirtualMFiControllerManager shared] disconnectController];
    });
  }

  [[TCDeviceMotion shared] setMotionEnabled:false];
}

- (void)documentPicker:(UIDocumentPickerViewController*)controller didPickDocumentsAtURLs:(NSArray<NSURL*>*)urls {
    NSString* sourcePath = [urls[0] path];
    std::string path = std::string([sourcePath UTF8String]);
    File::IOFile sky_file(path, "r+b");
    if (!sky_file)
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Failed to Open Skylander File!"
                                       message:nil
                                       preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    std::array<u8, 0x40 * 0x10> file_data;
    if (!sky_file.ReadBytes(file_data.data(), file_data.size()))
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Failed to Read Skylander File!"
                                       message:nil
                                       preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    auto& system = Core::System::GetInstance();
    std::pair<u16, u16> id_var = system.GetSkylanderPortal().CalculateIDs(file_data);
    u8 portal_slot = system.GetSkylanderPortal().LoadSkylander(std::make_unique<IOS::HLE::USB::SkylanderFigure>(std::move(sky_file)));
    if (portal_slot == 0xFF)
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Failed to Load Skylander File!"
                                       message:nil
                                       preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    self.skylanderSlot = portal_slot + 1;
}

@end
