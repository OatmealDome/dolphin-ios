// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include "InputCommon/ControllerInterface/iOS/iOS.h"

#include "InputCommon/ControllerInterface/iOS/StateManager.h"
#include "InputCommon/ControllerInterface/iOS/Touchscreen.h"

namespace ciface::iOS
{
void Init()
{
  StateManager::GetInstance()->Init();
}

void DeInit()
{
  StateManager::GetInstance()->DeInit();
}

void PopulateDevices()
{
  for (int i = 0; i < 8; ++i)
    g_controller_interface.AddDevice(std::make_shared<ciface::iOS::Touchscreen>(
        i, i >= 4));
}
}  // namespace ciface::iOS
