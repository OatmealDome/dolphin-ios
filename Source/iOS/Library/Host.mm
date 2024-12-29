// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include <string>
#include <vector>

#include <Foundation/Foundation.h>

#include "Core/Core.h"
#include "Core/Host.h"
#include "Core/System.h"

#include "HostNotifications.h"
#include "HostQueue.h"

std::vector<std::string> Host_GetPreferredLocales()
{
  return {};
}

void Host_PPCSymbolsChanged()
{
}

void Host_PPCBreakpointsChanged()
{
}

void Host_RefreshDSPDebuggerWindow()
{
}

void Host_Message(HostMessageID message)
{
  if (message == HostMessageID::WMUserJobDispatch)
  {
    DOLHostQueueRunAsync(^{
      Core::HostDispatchJobs(Core::System::GetInstance());
    });
  }
  else if (message == HostMessageID::WMUserStop)
  {
    if (Core::IsRunning(Core::System::GetInstance()))
    {
      Core::QueueHostJob(&Core::Stop);
    }
  }
}

void Host_UpdateTitle(const std::string&)
{
}

void Host_UpdateDiscordClientID(const std::string& client_id)
{
}

bool Host_UpdateDiscordPresenceRaw(const std::string& details, const std::string& state,
                                   const std::string& large_image_key,
                                   const std::string& large_image_text,
                                   const std::string& small_image_key,
                                   const std::string& small_image_text,
                                   const int64_t start_timestamp, const int64_t end_timestamp,
                                   const int party_size, const int party_max)
{
  return false;
}

void Host_UpdateDisasmDialog()
{
}

void Host_JitCacheInvalidation()
{
}

void Host_JitProfileDataWiped()
{
}

void Host_UpdateMainFrame()
{
}

void Host_RequestRenderWindowSize(int, int)
{
  [[NSNotificationCenter defaultCenter] postNotificationName:DOLHostRequestRenderWindowSizeNotification object:nil];
}

bool Host_UIBlocksControllerState()
{
  return false;
}

bool Host_RendererHasFocus()
{
  return true;
}

bool Host_RendererHasFullFocus()
{
  return true;
}

bool Host_RendererIsFullscreen()
{
  return true;
}

bool Host_TASInputHasFocus()
{
  return false;
}

void Host_YieldToUI()
{
}

void Host_TitleChanged()
{
  [[NSNotificationCenter defaultCenter] postNotificationName:DOLHostTitleChangedNotification object:nil];
}

std::unique_ptr<GBAHostInterface> Host_CreateGBAHost(std::weak_ptr<HW::GBA::Core> core)
{
  return nullptr;
}
