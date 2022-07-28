// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include "InputCommon/ControllerInterface/iOS/iOS.h"

#include "Common/MRCHelpers.h"

#include "InputCommon/ControllerInterface/iOS/MFiController.h"
#include "InputCommon/ControllerInterface/iOS/MFiControllerScanner.h"
#include "InputCommon/ControllerInterface/iOS/StateManager.h"
#include "InputCommon/ControllerInterface/iOS/Touchscreen.h"

namespace ciface::iOS
{
MRCOwned<MFiControllerScanner*> g_mfi_scanner;

void Init()
{
  StateManager::GetInstance()->Init();

  g_mfi_scanner = MRCTransfer([[MFiControllerScanner alloc] init]);
}

void DeInit()
{
  StateManager::GetInstance()->DeInit();

  g_mfi_scanner.Reset();
}

void PopulateDevices()
{
  for (int i = 0; i < 8; ++i)
    g_controller_interface.AddDevice(std::make_shared<ciface::iOS::Touchscreen>(
        i, i >= 4));
  
  for (GCController* controller in [GCController controllers])
    g_controller_interface.AddDevice(std::make_shared<MFiController>(controller));
}
}  // namespace ciface::iOS
