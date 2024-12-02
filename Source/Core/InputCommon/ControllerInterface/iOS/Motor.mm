// Copyright 2020 Dolphin Emulator Project
// Licensed under GPLv2+
// Refer to the license.txt file included.

#include <CoreHaptics/CoreHaptics.h>
#include <Foundation/Foundation.h>

#include "Common/Logging/Log.h"

#include "InputCommon/ControllerInterface/ControllerInterface.h"
#include "InputCommon/ControllerInterface/iOS/Motor.h"

#define MOTOR_ERROR_LOG(x, y) ERROR_LOG_FMT(CONTROLLERINTERFACE, x, [[y localizedDescription] UTF8String])

namespace ciface::iOS
{
Motor::Motor(CHHapticEngine* engine, const std::string name) : m_haptic_engine(engine), m_name(std::move(name))
{
  std::lock_guard<std::mutex> guard(m_lock);

  if (!StartEngine())
  {
    return;
  }

  m_haptic_engine.resetHandler = ^{
    std::lock_guard<std::mutex> reset_guard(m_lock);

    m_player_created = false;

    m_haptic_player = nil;

    StartEngine();
  };

  m_haptic_engine.stoppedHandler = ^(CHHapticEngineStoppedReason reason) {
    std::lock_guard<std::mutex> stopped_guard(m_lock);

    switch (reason)
    {
    case CHHapticEngineStoppedReasonAudioSessionInterrupt:
    case CHHapticEngineStoppedReasonApplicationSuspended:
    case CHHapticEngineStoppedReasonSystemError:
      m_player_needs_restart = true;

      break;
    default:
      ERROR_LOG_FMT(CONTROLLERINTERFACE, "Motor received unexpected stopped reason: {}", (NSInteger)reason);

      // This error is probably unrecoverable.
      m_player_created = false;

      break;
    }
  };
}

Motor::~Motor()
{
  std::lock_guard<std::mutex> guard(m_lock);

  if (m_player_created)
  {
    [m_haptic_engine stopWithCompletionHandler:nil];
  }
}

bool Motor::StartEngine()
{
  NSError* error;
  
  if (![m_haptic_engine startAndReturnError:&error])
  {
    MOTOR_ERROR_LOG("Motor failed to start CHHapticEngine: {}", error);

    return false;
  }
  
  CHHapticEventParameter* intensity_param = [[CHHapticEventParameter alloc] initWithParameterID:CHHapticEventParameterIDHapticIntensity value:1.0f];

  CHHapticEvent* event = [[CHHapticEvent alloc] initWithEventType:CHHapticEventTypeHapticContinuous 
                                                       parameters:@[intensity_param]
                                                     relativeTime:0.0f
                                                         duration:1.0f];
  
  CHHapticPattern* pattern = [[CHHapticPattern alloc] initWithEvents:@[event] parameters:@[] error:&error];

  if (error != nil)
  {
    MOTOR_ERROR_LOG("Motor failed to create CHHapticPattern: {}", error);

    return false;
  }
  
  m_haptic_player = [m_haptic_engine createAdvancedPlayerWithPattern:pattern error:&error];

  if (error != nil)
  {
    MOTOR_ERROR_LOG("Motor failed to create CHHapticAdvancedPatternPlayer: {}", error);

    return false;
  }

  [m_haptic_player setLoopEnabled:true];
  [m_haptic_player setLoopEnd:0.0f];

  m_player_created = true;
  m_player_needs_restart = false;

  return true;
}

std::string Motor::GetName() const
{
  return m_name;
}

void Motor::SetState(ControlState state)
{
  std::lock_guard<std::mutex> guard(m_lock);

  if (!m_player_created || state == m_last_state)
  {
    return;
  }

  if (m_player_needs_restart)
  {
    if (!StartEngine())
    {
      return;
    }
  }
  
  bool result;
  NSError* error;
  
  if (state > 0)
  {
    result = [m_haptic_player startAtTime:CHHapticTimeImmediate error:&error];
  }
  else
  {
    result = [m_haptic_player stopAtTime:CHHapticTimeImmediate error:&error];
  }

  if (!result)
  {
    MOTOR_ERROR_LOG("Motor failed to start/stop haptics: {}", error);
  }

  m_last_state = state;
}
} // namespace ciface::iOS
