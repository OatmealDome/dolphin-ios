// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "ConfigAdvancedViewController.h"

#import <cmath>

#import "Core/Config/MainSettings.h"
#import "Core/HW/SystemTimers.h"
#import "Core/HW/VideoInterface.h"
#import "Core/System.h"
#import "Core/PowerPC/PowerPC.h"

#import "LocalizationUtil.h"

@interface ConfigAdvancedViewController ()

@end

@implementation ConfigAdvancedViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.mmuSwitch.on = Config::Get(Config::MAIN_MMU);
  [self.mmuSwitch addValueChangedTarget:self action:@selector(mmuChanged)];
  
  self.panicPauseSwitch.on = Config::Get(Config::MAIN_PAUSE_ON_PANIC);
  [self.panicPauseSwitch addValueChangedTarget:self action:@selector(panicPauseChanged)];
  
  self.writeBackCacheSwitch.on = Config::Get(Config::MAIN_ACCURATE_CPU_CACHE);
  [self.writeBackCacheSwitch addValueChangedTarget:self action:@selector(writeBackCacheChanged)];
  
  self.cpuClockSwitch.on = Config::Get(Config::MAIN_OVERCLOCK_ENABLE);
  [self.cpuClockSwitch addValueChangedTarget:self action:@selector(cpuClockSwitchChanged)];
  
  self.cpuClockSlider.value = std::round(std::log2f(Config::Get(Config::MAIN_OVERCLOCK)) * 25.f + 100.f);
  self.cpuClockSlider.enabled = self.cpuClockSwitch.on;
  
  [self setCpuClockLabel];
  
  self.vbiClockSwitch.on = Config::Get(Config::MAIN_VI_OVERCLOCK_ENABLE);
  [self.vbiClockSwitch addValueChangedTarget:self action:@selector(vbiClockSwitchChanged)];
  
  self.vbiClockSlider.value = std::round(std::log2f(Config::Get(Config::MAIN_VI_OVERCLOCK)) * 25.f + 100.f);
  self.vbiClockSlider.enabled = self.vbiClockSwitch.on;
  
  [self setVbiClockLabel];
  
  self.memorySwitch.on = Config::Get(Config::MAIN_RAM_OVERRIDE_ENABLE);
  [self.memorySwitch addValueChangedTarget:self action:@selector(memorySwitchChanged)];
  
  self.memOneSlider.value = Config::Get(Config::MAIN_MEM1_SIZE) / 0x100000;
  self.memOneSlider.enabled = self.memorySwitch.on;
  
  [self setMemOneLabel];
  
  self.memTwoSlider.value = Config::Get(Config::MAIN_MEM2_SIZE) / 0x100000;
  self.memTwoSlider.enabled = self.memorySwitch.on;
  
  [self setMemTwoLabel];
  
  self.rtcSwitch.on = Config::Get(Config::MAIN_CUSTOM_RTC_ENABLE);
  [self.rtcSwitch addValueChangedTarget:self action:@selector(rtcSwitchChanged)];
  
  self.rtcPicker.date = [NSDate dateWithTimeIntervalSince1970:Config::Get(Config::MAIN_CUSTOM_RTC_VALUE)];
  self.rtcPicker.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
  self.rtcPicker.enabled = self.rtcSwitch.on;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  NSString* cpuCore;
  switch (Config::Get(Config::MAIN_CPU_CORE)) {
    case PowerPC::CPUCore::Interpreter:
      cpuCore = @"Interpreter (slowest)";
      break;
    case PowerPC::CPUCore::CachedInterpreter:
      cpuCore = @"Cached Interpreter (slower)";
      break;
    case PowerPC::CPUCore::JIT64:
      cpuCore = @"JIT Recompiler for x86-64 (recommended)";
      break;
    case PowerPC::CPUCore::JITARM64:
      cpuCore = @"JIT Recompiler for ARM64 (recommended)";
      break;
    default:
      cpuCore = @"Error";
      break;
  }
  
  self.engineLabel.text = DOLCoreLocalizedString(cpuCore);
}

- (void)mmuChanged {
  Config::SetBaseOrCurrent(Config::MAIN_MMU, self.mmuSwitch.on);
}

- (void)panicPauseChanged {
  Config::SetBaseOrCurrent(Config::MAIN_PAUSE_ON_PANIC, self.panicPauseSwitch.on);
}

- (void)writeBackCacheChanged {
  Config::SetBaseOrCurrent(Config::MAIN_ACCURATE_CPU_CACHE, self.writeBackCacheSwitch.on);
}

- (void)cpuClockSwitchChanged {
  bool enabled = self.cpuClockSwitch.on;
  
  Config::SetBaseOrCurrent(Config::MAIN_OVERCLOCK_ENABLE, enabled);
  self.cpuClockSlider.enabled = enabled;
  
  // There is a bug on iOS 14+ where a UISlider won't update its appearance when enabled is toggled.
  [self.cpuClockSlider setNeedsLayout];
  [self.cpuClockSlider layoutIfNeeded];
}

- (IBAction)cpuClockSliderChanged:(id)sender {
  const float overclock = std::exp2f((self.cpuClockSlider.value - 100.f) / 25.f);
  
  Config::SetBaseOrCurrent(Config::MAIN_OVERCLOCK, overclock);
  
  [self setCpuClockLabel];
}

- (void)setCpuClockLabel {
  int core_clock = Core::System::GetInstance().GetSystemTimers().GetTicksPerSecond() / std::pow(10, 6);
  const float overclock = Config::Get(Config::MAIN_OVERCLOCK);
  int percent = static_cast<int>(std::round(overclock * 100.f));
  int clock = static_cast<int>(std::round(overclock * core_clock));
  
  self.cpuClockLabel.text = [NSString stringWithFormat:@"%d%% (%d MHz)", percent, clock];
}

- (void)vbiClockSwitchChanged {
  bool enabled = self.vbiClockSwitch.on;
  
  Config::SetBaseOrCurrent(Config::MAIN_VI_OVERCLOCK_ENABLE, enabled);
  self.vbiClockSlider.enabled = enabled;
  
  // There is a bug on iOS 14+ where a UISlider won't update its appearance when enabled is toggled.
  [self.vbiClockSlider setNeedsLayout];
  [self.vbiClockSlider layoutIfNeeded];
}

- (IBAction)vbiClockSliderChanged:(id)sender {
  const float factor = std::exp2f((self.vbiClockSlider.value - 100.f) / 21.5);
  
  Config::SetBaseOrCurrent(Config::MAIN_VI_OVERCLOCK, factor);
  
  [self setVbiClockLabel];
}

- (void)setVbiClockLabel {
  const float factor = Config::Get(Config::MAIN_VI_OVERCLOCK);
  int percent = static_cast<int>(std::round(factor * 100.f));
  float vps = static_cast<float>(Core::System::GetInstance().GetVideoInterface().GetTargetRefreshRate());
  vps = 59.94f * Config::Get(Config::MAIN_VI_OVERCLOCK);
  
  self.vbiClockLabel.text = [NSString stringWithFormat:@"%d%% (%f VPS)", percent, vps];
}

- (void)memorySwitchChanged {
  bool enabled = self.memorySwitch.on;
  
  Config::SetBaseOrCurrent(Config::MAIN_RAM_OVERRIDE_ENABLE, enabled);
  self.memOneSlider.enabled = enabled;
  self.memTwoSlider.enabled = enabled;
  
  [self.memOneSlider setNeedsLayout];
  [self.memOneSlider layoutIfNeeded];
  
  [self.memTwoSlider setNeedsLayout];
  [self.memTwoSlider layoutIfNeeded];
}

- (IBAction)memOneSliderChanged:(id)sender {
  Config::SetBaseOrCurrent(Config::MAIN_MEM1_SIZE, self.memOneSlider.value * 0x100000);
  
  [self setMemOneLabel];
}

- (void)setMemOneLabel {
  // TODO: "MB" isn't applicable to all language, but there isn't a good Core string to use here...
  self.memOneLabel.text = [NSString stringWithFormat:@"%d MB", Config::Get(Config::MAIN_MEM1_SIZE) / 0x100000];
}

- (IBAction)memTwoSliderChanged:(id)sender {
  Config::SetBaseOrCurrent(Config::MAIN_MEM2_SIZE, self.memTwoSlider.value * 0x100000);
  
  [self setMemTwoLabel];
}

- (void)setMemTwoLabel {
  // TODO: See comment on MEM1 above.
  self.memTwoLabel.text = [NSString stringWithFormat:@"%d MB", Config::Get(Config::MAIN_MEM2_SIZE) / 0x100000];
}

- (void)rtcSwitchChanged {
  bool enabled = self.rtcSwitch.on;
  
  Config::SetBaseOrCurrent(Config::MAIN_CUSTOM_RTC_ENABLE, enabled);
  self.rtcPicker.enabled = enabled;
}

- (IBAction)rtcPickerChanged:(id)sender {
  Config::SetBaseOrCurrent(Config::MAIN_CUSTOM_RTC_VALUE, [self.rtcPicker.date timeIntervalSince1970]);
}

@end
