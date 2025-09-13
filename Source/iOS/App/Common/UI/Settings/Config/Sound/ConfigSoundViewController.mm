// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "ConfigSoundViewController.h"

#import "Core/Config/iOSSettings.h"
#import "Core/Config/MainSettings.h"

#import "AudioSessionManager.h"
#import "FoundationStringUtil.h"
#import "LocalizationUtil.h"

#import "Swift.h"

@interface ConfigSoundViewController ()

@end

@implementation ConfigSoundViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  int volume = Config::Get(Config::MAIN_AUDIO_VOLUME);
  self.volumeSlider.value = volume;
  
  [self updateVolumeLabel];
  
  self.bufferSizeSlider.value = Config::Get(Config::MAIN_AUDIO_BUFFER_SIZE);
  
  [self updateBufferSizeLabel];
  
  self.fillGapsSwitch.on = Config::Get(Config::MAIN_AUDIO_FILL_GAPS);
  
  self.muteSpeedLimitSwitch.on = Config::Get(Config::MAIN_AUDIO_MUTE_ON_DISABLED_SPEED_LIMIT);
  [self.muteSpeedLimitSwitch addValueChangedTarget:self action:@selector(muteSpeedLimitChanged)];
  
  AudioMuteSwitchMode muteSwitchMode = (AudioMuteSwitchMode)Config::Get(Config::MAIN_MUTE_SWITCH_MODE);
  self.muteModeSwitch.on = muteSwitchMode == AudioMuteSwitchModeObey;
  [self.muteModeSwitch addValueChangedTarget:self action:@selector(muteModeSwitchChanged)];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  self.backendLabel.text = CppToFoundationString(Config::Get(Config::MAIN_AUDIO_BACKEND));
}

- (IBAction)volumeChanged:(id)sender {
  Config::SetBaseOrCurrent(Config::MAIN_AUDIO_VOLUME, (int)self.volumeSlider.value);
  
  [self updateVolumeLabel];
}

- (void)updateVolumeLabel {
  int volume = Config::Get(Config::MAIN_AUDIO_VOLUME);
  self.volumeLabel.text = [NSString stringWithFormat:@"%d%%", volume];
}

- (IBAction)bufferSizeChanged:(id)sender {
  Config::SetBaseOrCurrent(Config::MAIN_AUDIO_BUFFER_SIZE, (int)self.bufferSizeSlider.value);
  
  [self updateBufferSizeLabel];
}

- (void)updateBufferSizeLabel {
  int bufferSize = Config::Get(Config::MAIN_AUDIO_BUFFER_SIZE);
  self.bufferSizeLabel.text = [NSString stringWithFormat:DOLCoreLocalizedStringWithArgs(@"%1 ms", @"d"), bufferSize];
}

- (IBAction)fillGapsChanged:(id)sender {
  Config::SetBaseOrCurrent(Config::MAIN_AUDIO_FILL_GAPS, self.fillGapsSwitch.on);
}

- (void)muteSpeedLimitChanged {
  Config::SetBaseOrCurrent(Config::MAIN_AUDIO_MUTE_ON_DISABLED_SPEED_LIMIT, self.muteSpeedLimitSwitch.on);
}

- (void)muteModeSwitchChanged {
  AudioMuteSwitchMode mode;
  
  if (self.muteModeSwitch.on) {
    mode = AudioMuteSwitchModeObey;
  } else {
    mode = AudioMuteSwitchModeIgnore;
  }
  
  Config::SetBaseOrCurrent(Config::MAIN_MUTE_SWITCH_MODE, (int)mode);
  
  [[AudioSessionManager shared] setSessionCategory];
}

@end
