// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include "InputCommon/ControllerInterface/iOS/iOS.h"

#include "InputCommon/ControllerInterface/InputBackend.h"
#include "InputCommon/ControllerInterface/iOS/MFiController.h"
#include "InputCommon/ControllerInterface/iOS/MFiControllerScanner.h"
#include "InputCommon/ControllerInterface/iOS/StateManager.h"
#include "InputCommon/ControllerInterface/iOS/Touchscreen.h"

namespace ciface::iOS
{
class InputBackend final : public ciface::InputBackend
{
public:
  using ciface::InputBackend::InputBackend;
  ~InputBackend();
  void PopulateDevices() override;

};

std::unique_ptr<ciface::InputBackend> CreateInputBackend(ControllerInterface* controller_interface)
{
  return std::make_unique<InputBackend>(controller_interface);
}

InputBackend::~InputBackend()
{
}

static MFiControllerScanner* g_mfi_scanner;

void Init()
{
  StateManager::GetInstance()->Init();

  g_mfi_scanner = [[MFiControllerScanner alloc] init];
}

void DeInit()
{
  StateManager::GetInstance()->DeInit();

  g_mfi_scanner = nil;
}

void InputBackend::PopulateDevices()
{
  for (int i = 0; i < 8; ++i)
    GetControllerInterface().AddDevice(std::make_shared<ciface::iOS::Touchscreen>(
        i, i >= 4));
  
  for (GCController* controller in [GCController controllers])
    GetControllerInterface().AddDevice(std::make_shared<MFiController>(controller));
}
}  // namespace ciface::iOS
