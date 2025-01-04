// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include "Core/Config/iOSSettings.h"

namespace Config
{
// Main.iOS

const Info<float> MAIN_TOUCH_PAD_OPACITY{{System::Main, "iOS", "TouchPadOpacity"}, 0.50f};
const Info<int> MAIN_TOUCH_PAD_IR_MODE{{System::Main, "iOS", "TouchPadIRMode"}, 2};
const Info<int> MAIN_SELECTED_STATE_SLOT{{System::Main, "iOS", "SelectedStateSlot"}, 1};
const Info<int> MAIN_MUTE_SWITCH_MODE{{System::Main, "iOS", "MuteSwitchMode"}, 0};

}  // namespace Config
