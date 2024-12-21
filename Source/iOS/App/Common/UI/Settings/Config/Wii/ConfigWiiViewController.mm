// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "ConfigWiiViewController.h"

#import "Core/Config/MainSettings.h"
#import "Core/Config/SYSCONFSettings.h"

#import "LocalizationUtil.h"

@interface ConfigWiiViewController ()

@end

@implementation ConfigWiiViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.palSwitch.on = Config::Get(Config::SYSCONF_PAL60);
  [self.palSwitch addValueChangedTarget:self action:@selector(palChanged)];
  
  self.screenSaverSwitch.on = Config::Get(Config::SYSCONF_SCREENSAVER);
  [self.screenSaverSwitch addValueChangedTarget:self action:@selector(screenSaverChanged)];
  
  self.usbKeyboardSwitch.on = Config::Get(Config::MAIN_WII_KEYBOARD);
  [self.usbKeyboardSwitch addValueChangedTarget:self action:@selector(usbKeyboardChanged)];
  
  self.wc24Switch.on = Config::Get(Config::MAIN_WII_WIILINK_ENABLE);
  [self.wc24Switch addValueChangedTarget:self action:@selector(wc24Changed)];
  
  self.sdInsertedSwitch.on = Config::Get(Config::MAIN_WII_SD_CARD);
  [self.sdInsertedSwitch addValueChangedTarget:self action:@selector(sdInsertedChanged)];
  
  self.sdWritesSwitch.on = Config::Get(Config::MAIN_ALLOW_SD_WRITES);
  [self.sdWritesSwitch addValueChangedTarget:self action:@selector(sdWritesChanged)];
  
  self.sdSyncSwitch.on = Config::Get(Config::MAIN_WII_SD_CARD_ENABLE_FOLDER_SYNC);
  [self.sdSyncSwitch addValueChangedTarget:self action:@selector(sdSyncChanged)];
  
  self.irSlider.value = Config::Get(Config::SYSCONF_SENSOR_BAR_SENSITIVITY);
  
  self.speakerVolumeSlider.value = Config::Get(Config::SYSCONF_SPEAKER_VOLUME);
  
  self.rumbleSwitch.on = Config::Get(Config::SYSCONF_WIIMOTE_MOTOR);
  [self.rumbleSwitch addValueChangedTarget:self action:@selector(rumbleChanged)];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  NSString* aspectRatio;
  if (Config::Get(Config::SYSCONF_WIDESCREEN)) {
    aspectRatio = @"16:9";
  } else {
    aspectRatio = @"4:3";
  }
  
  self.aspectRatioLabel.text = DOLCoreLocalizedString(aspectRatio);
  
  NSString* language;
  switch (Config::Get(Config::SYSCONF_LANGUAGE)) {
    case 0:
      language = @"Japanese";
      break;
    case 1:
      language = @"English";
      break;
    case 2:
      language = @"German";
      break;
    case 3:
      language = @"French";
      break;
    case 4:
      language = @"Spanish";
      break;
    case 5:
      language = @"Italian";
      break;
    case 6:
      language = @"Dutch";
      break;
    case 7:
      language = @"Simplified Chinese";
      break;
    case 8:
      language = @"Traditional Chinese";
      break;
    case 9:
      language = @"Korean";
      break;
    default:
      language = @"Error";
      break;
  }
  
  self.languageLabel.text = DOLCoreLocalizedString(language);
  
  NSString* audioMode;
  switch (Config::Get(Config::SYSCONF_SOUND_MODE)) {
    case 0:
      audioMode = @"Mono";
      break;
    case 1:
      audioMode = @"Stereo";
      break;
    case 2:
      audioMode = @"Surround";
      break;
    default:
      audioMode = @"Error";
      break;
  }
  
  self.audioLabel.text = DOLCoreLocalizedString(audioMode);
  
  NSString* position;
  if (Config::Get(Config::SYSCONF_SENSOR_BAR_POSITION) == 0) {
    position = @"Bottom";
  } else {
    position = @"Top";
  }
  
  self.sensorBarLabel.text = DOLCoreLocalizedString(position);
}

- (void)palChanged {
  Config::SetBase(Config::SYSCONF_PAL60, self.palSwitch.on);
}

- (void)screenSaverChanged {
  Config::SetBase(Config::SYSCONF_SCREENSAVER, self.screenSaverSwitch.on);
}

- (void)usbKeyboardChanged {
  Config::SetBaseOrCurrent(Config::MAIN_WII_KEYBOARD, self.usbKeyboardSwitch.on);
}

- (void)wc24Changed {
  Config::SetBase(Config::MAIN_WII_WIILINK_ENABLE, self.wc24Switch.on);
}

- (void)sdInsertedChanged {
  Config::SetBaseOrCurrent(Config::MAIN_WII_SD_CARD, self.sdInsertedSwitch.on);
}

- (void)sdWritesChanged {
  Config::SetBase(Config::MAIN_ALLOW_SD_WRITES, self.sdWritesSwitch.on);
}

- (void)sdSyncChanged {
  Config::SetBase(Config::MAIN_WII_SD_CARD_ENABLE_FOLDER_SYNC, self.sdSyncSwitch.on);
}

- (IBAction)irChanged:(id)sender {
  Config::SetBase(Config::SYSCONF_SENSOR_BAR_SENSITIVITY, (int)self.irSlider.value);
  self.irSlider.value = (int)self.irSlider.value;
}

- (IBAction)speakerVolumeChanged:(id)sender {
  Config::SetBase(Config::SYSCONF_SPEAKER_VOLUME, (int)self.speakerVolumeSlider.value);
  self.speakerVolumeSlider.value = (int)self.speakerVolumeSlider.value;
}

- (void)rumbleChanged {
  Config::SetBase(Config::SYSCONF_WIIMOTE_MOTOR, self.rumbleSwitch.on);
}

@end
