// Copyright 2025 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "AudioSessionManager.h"

#import <AVFoundation/AVFoundation.h>

#import "Core/Config/iOSSettings.h"

#import "Swift.h"

@implementation AudioSessionManager

+ (AudioSessionManager*)shared {
  static AudioSessionManager* sharedInstance = nil;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });

  return sharedInstance;
}

- (void)setSessionCategory {
  AVAudioSession* session = [AVAudioSession sharedInstance];
  
  AudioMuteSwitchMode mode = (AudioMuteSwitchMode)Config::Get(Config::MAIN_MUTE_SWITCH_MODE);
  
  if (mode == AudioMuteSwitchModeObey) {
    [session setCategory:AVAudioSessionCategorySoloAmbient error:nil];
  } else {
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
  }
}

@end
