// Copyright 2008 Dolphin Emulator Project
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#ifdef IPHONEOS
#include <AudioUnit/AudioUnit.h>
#endif

#include "AudioCommon/SoundStream.h"

class CoreAudioSound final : public SoundStream
{
#ifdef IPHONEOS
public:
  bool Init() override;
  bool SetRunning(bool running) override;
  void SetVolume(int volume) override;

  static bool IsValid() { return true; }

private:
  AudioUnit audio_unit;
  int m_volume;

  static OSStatus callback(void* ref_con, AudioUnitRenderActionFlags* action_flags,
                           const AudioTimeStamp* timestamp, UInt32 bus_number, UInt32 number_frames,
                           AudioBufferList* io_data);
#endif
};
