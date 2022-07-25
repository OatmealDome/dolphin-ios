// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include <string>
#include <vector>

#include <Foundation/Foundation.h>

#include "Core/Core.h"
#include "Core/Host.h"

#include "HostNotifications.h"

std::vector<std::string> Host_GetPreferredLocales()
{
  return {};
}

void Host_NotifyMapLoaded()
{
}

void Host_RefreshDSPDebuggerWindow()
{
}

void Host_Message(HostMessageID message)
{
  if (message == HostMessageID::WMUserJobDispatch)
  {
    [[NSNotificationCenter defaultCenter] postNotificationName:DOLHostDidReceiveDispatchJobNotification object:nil];
  }
  else if (message == HostMessageID::WMUserStop)
  {
    if (Core::IsRunning())
    {
      Core::QueueHostJob(&Core::Stop);
    }
  }
}

void Host_UpdateTitle(const std::string&)
{
}

void Host_UpdateDisasmDialog()
{
}

void Host_UpdateMainFrame()
{
}

void Host_RequestRenderWindowSize(int, int)
{
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
