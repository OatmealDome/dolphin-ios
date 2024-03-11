// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "CpuEngineViewController.h"

#import "Core/Config/MainSettings.h"
#import "Core/PowerPC/PowerPC.h"

#import "CpuEngineCell.h"
#import "LocalizationUtil.h"

@interface CpuEngineViewController ()

@end

@implementation CpuEngineViewController {
  NSInteger _lastSelected;
  std::span<const PowerPC::CPUCore> _cores;
}

#pragma mark - Table view data source

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  _cores = PowerPC::AvailableCPUCores();
  
  const auto currentCore = Config::Get(Config::MAIN_CPU_CORE);
  for (NSInteger i = 0; i < _cores.size(); i++) {
    if (currentCore == _cores[i]) {
      _lastSelected = i;
      break;
    }
  }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
  return _cores.size();
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  CpuEngineCell* cell = [tableView dequeueReusableCellWithIdentifier:@"EngineCell" forIndexPath:indexPath];
  
  NSString* cpuCore;
  switch (_cores[indexPath.row]) {
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
  
  cell.engineCell.text = DOLCoreLocalizedString(cpuCore);
  
  if (indexPath.row == _lastSelected) {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  } else {
    cell.accessoryType = UITableViewCellAccessoryNone;
  }
  
  return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  if (_lastSelected != indexPath.row) {
    Config::SetBaseOrCurrent(Config::MAIN_CPU_CORE, _cores[indexPath.row]);

    CpuEngineCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    CpuEngineCell* oldCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_lastSelected inSection:0]];
    oldCell.accessoryType = UITableViewCellAccessoryNone;
    
    _lastSelected = indexPath.row;
  }
  
  [tableView deselectRowAtIndexPath:indexPath animated:true];
}

@end
