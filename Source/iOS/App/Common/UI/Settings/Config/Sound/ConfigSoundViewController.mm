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
  
  bool stretchingEnabled = Config::Get(Config::MAIN_AUDIO_STRETCH);
  
  self.stretchingSwitch.on = stretchingEnabled;
  [self.stretchingSwitch addValueChangedTarget:self action:@selector(stretchingChanged)];
  
  int volume = Config::Get(Config::MAIN_AUDIO_VOLUME);
  self.volumeSlider.value = volume;
  
  [self updateVolumeLabel];
  
  self.bufferSizeSlider.value = Config::Get(Config::MAIN_AUDIO_STRETCH_LATENCY);
  self.bufferSizeSlider.enabled = stretchingEnabled;
  
  [self updateBufferSizeLabel];
  
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

- (void)stretchingChanged {
  bool stretchingEnabled = self.stretchingSwitch.on;
  
  Config::SetBaseOrCurrent(Config::MAIN_AUDIO_STRETCH, stretchingEnabled);
  
  self.bufferSizeSlider.enabled = stretchingEnabled;
  
  // There is a bug on iOS 14+ where a UISlider won't update its appearance when enabled is toggled.
  [self.bufferSizeSlider setNeedsLayout];
  [self.bufferSizeSlider layoutIfNeeded];
}

- (IBAction)bufferSizeChanged:(id)sender {
  Config::SetBaseOrCurrent(Config::MAIN_AUDIO_STRETCH_LATENCY, (int)self.bufferSizeSlider.value);
  
  [self updateBufferSizeLabel];
}

- (void)updateBufferSizeLabel {
  int bufferSize = Config::Get(Config::MAIN_AUDIO_STRETCH_LATENCY);
  self.bufferSizeLabel.text = [NSString stringWithFormat:DOLCoreLocalizedStringWithArgs(@"%1 ms", @"d"), bufferSize];
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
