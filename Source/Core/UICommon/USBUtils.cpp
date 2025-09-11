// Copyright 2017 Dolphin Emulator Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include "UICommon/USBUtils.h"

#include <string_view>

#include <fmt/format.h>
#ifdef __LIBUSB__
#include <libusb.h>
#endif

#include "Common/CommonTypes.h"
#include "Common/Logging/Log.h"
#include "Core/LibusbUtils.h"

// Because opening and getting the device name from devices is slow, especially on Windows
// with usbdk, we cannot do that for every single device. We should however still show
// device names for known Wii peripherals.
static const std::map<std::pair<u16, u16>, std::string_view> s_known_peripherals{{
    {{0x046d, 0x0a03}, "Logitech Microphone"},
    {{0x057e, 0x0308}, "Wii Speak"},
    {{0x057e, 0x0309}, "Nintendo USB Microphone"},
    {{0x057e, 0x030a}, "Ubisoft Motion Tracking Camera"},
    {{0x0e6f, 0x0129}, "Disney Infinity Reader (Portal Device)"},
    {{0x12ba, 0x0200}, "Harmonix Guitar for PlayStation 3"},
    {{0x12ba, 0x0210}, "Harmonix Drum Kit for PlayStation 3"},
    {{0x12ba, 0x0218}, "Harmonix Drum Kit for PlayStation 3"},
    {{0x12ba, 0x2330}, "Harmonix RB3 Keyboard for PlayStation 3"},
    {{0x12ba, 0x2338}, "Harmonix RB3 MIDI Keyboard Interface for PlayStation 3"},
    {{0x12ba, 0x2430}, "Harmonix RB3 Mustang Guitar for PlayStation 3"},
    {{0x12ba, 0x2438}, "Harmonix RB3 MIDI Guitar Interface for PlayStation 3"},
    {{0x12ba, 0x2530}, "Harmonix RB3 Squier Guitar for PlayStation 3"},
    {{0x12ba, 0x2538}, "Harmonix RB3 MIDI Guitar Interface for PlayStation 3"},
    {{0x1430, 0x0100}, "Tony Hawk Ride Skateboard"},
    {{0x1430, 0x0150}, "Skylanders Portal"},
    {{0x1bad, 0x0004}, "Harmonix Guitar Controller for Nintendo Wii"},
    {{0x1bad, 0x0005}, "Harmonix Drum Controller for Nintendo Wii"},
    {{0x1bad, 0x3010}, "Harmonix Guitar Controller for Nintendo Wii"},
    {{0x1bad, 0x3110}, "Harmonix Drum Controller for Nintendo Wii"},
    {{0x1bad, 0x3138}, "Harmonix Drum Controller for Nintendo Wii"},
    {{0x1bad, 0x3330}, "Harmonix RB3 Keyboard for Nintendo Wii"},
    {{0x1bad, 0x3338}, "Harmonix RB3 MIDI Keyboard Interface for Nintendo Wii"},
    {{0x1bad, 0x3430}, "Harmonix RB3 Mustang Guitar for Nintendo Wii"},
    {{0x1bad, 0x3438}, "Harmonix RB3 MIDI Guitar Interface for Nintendo Wii"},
    {{0x1bad, 0x3530}, "Harmonix RB3 Squier Guitar for Nintendo Wii"},
    {{0x1bad, 0x3538}, "Harmonix RB3 MIDI Guitar Interface for Nintendo Wii"},
    {{0x21a4, 0xac40}, "EA Active NFL"},
}};

namespace USBUtils
{
std::map<std::pair<u16, u16>, std::string> GetInsertedDevices()
{
  std::map<std::pair<u16, u16>, std::string> devices;

#ifdef __LIBUSB__
  LibusbUtils::Context context;
  if (!context.IsValid())
    return devices;

  const int ret = context.GetDeviceList([&](libusb_device* device) {
    libusb_device_descriptor descr;
    libusb_get_device_descriptor(device, &descr);
    const std::pair<u16, u16> vid_pid{descr.idVendor, descr.idProduct};
    devices[vid_pid] = GetDeviceName(vid_pid);
    return true;
  });
  if (ret != LIBUSB_SUCCESS)
    WARN_LOG_FMT(COMMON, "GetDeviceList failed: {}", LibusbUtils::ErrorWrap(ret));
#endif

  return devices;
}

std::string GetDeviceName(const std::pair<u16, u16> vid_pid)
{
  const auto iter = s_known_peripherals.find(vid_pid);
  const std::string_view device_name =
      iter == s_known_peripherals.cend() ? "Unknown" : iter->second;
  return fmt::format("{:04x}:{:04x} - {}", vid_pid.first, vid_pid.second, device_name);
}
}  // namespace USBUtils
