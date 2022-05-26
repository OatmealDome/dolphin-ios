// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include <string>
#include <vector>

#include <Foundation/Foundation.h>

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
  return false;
}

bool Host_RendererHasFullFocus()
{
  return false;
}

bool Host_RendererIsFullscreen()
{
  return false;
}

void Host_YieldToUI()
{
}

void Host_TitleChanged()
{
}

std::unique_ptr<GBAHostInterface> Host_CreateGBAHost(std::weak_ptr<HW::GBA::Core> core)
{
  return nullptr;
}
