// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include "InputCommon/ControllerInterface/iOS/iOS.h"

#include "InputCommon/ControllerInterface/iOS/StateManager.h"

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
}
}  // namespace ciface::iOS
