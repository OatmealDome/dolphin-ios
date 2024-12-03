// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include "InputCommon/ControllerInterface/iOS/iOS.h"

#include "InputCommon/ControllerInterface/iOS/MFiController.h"
#include "InputCommon/ControllerInterface/iOS/MFiControllerScanner.h"
#include "InputCommon/ControllerInterface/iOS/StateManager.h"
#include "InputCommon/ControllerInterface/iOS/Touchscreen.h"

namespace ciface::iOS
{
class InputBackend final : public ciface::InputBackend
{
public:
  InputBackend(ControllerInterface* controller_interface);
  ~InputBackend();
  void PopulateDevices() override;

private:
  MFiControllerScanner* m_mfi_scanner;
};

std::unique_ptr<ciface::InputBackend> CreateInputBackend(ControllerInterface* controller_interface)
{
  return std::make_unique<InputBackend>(controller_interface);
}

InputBackend::InputBackend(ControllerInterface* controller_interface)
    : ciface::InputBackend(controller_interface)
{
  StateManager::GetInstance()->Init();

  m_mfi_scanner = [[MFiControllerScanner alloc] init];
}

InputBackend::~InputBackend()
{
  StateManager::GetInstance()->DeInit();

  m_mfi_scanner = nil;
}

void InputBackend::PopulateDevices()
{
  for (int i = 0; i < 8; ++i)
    g_controller_interface.AddDevice(std::make_shared<ciface::iOS::Touchscreen>(
        i, i >= 4));
  
  for (GCController* controller in [GCController controllers])
    g_controller_interface.AddDevice(std::make_shared<MFiController>(controller));
}
}  // namespace ciface::iOS
