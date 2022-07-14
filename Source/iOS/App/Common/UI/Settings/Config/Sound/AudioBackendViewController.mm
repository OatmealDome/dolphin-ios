// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "AudioBackendViewController.h"

#import "AudioCommon/AudioCommon.h"

#import "Core/Config/MainSettings.h"

#import "AudioBackendCell.h"
#import "FoundationStringUtil.h"

@interface AudioBackendViewController ()

@end

@implementation AudioBackendViewController {
  NSInteger _lastSelected;
  std::vector<std::string> _backends;
}

#pragma mark - Table view data source

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  _backends = AudioCommon::GetSoundBackends();
  
  const auto currentBackend = Config::Get(Config::MAIN_AUDIO_BACKEND);
  for (NSInteger i = 0; i < _backends.size(); i++) {
    if (currentBackend == _backends.at(i)) {
      _lastSelected = i;
      break;
    }
  }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
  return AudioCommon::GetSoundBackends().size();
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  AudioBackendCell* cell = [tableView dequeueReusableCellWithIdentifier:@"BackendCell" forIndexPath:indexPath];
  
  cell.backendLabel.text = CppToFoundationString(_backends.at(indexPath.row));
  
  if (indexPath.row == _lastSelected) {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  } else {
    cell.accessoryType = UITableViewCellAccessoryNone;
  }
  
  return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  if (_lastSelected != indexPath.row) {
    Config::SetBaseOrCurrent(Config::MAIN_AUDIO_BACKEND, _backends.at(indexPath.row));

    AudioBackendCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    AudioBackendCell* oldCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_lastSelected inSection:0]];
    oldCell.accessoryType = UITableViewCellAccessoryNone;
    
    _lastSelected = indexPath.row;
  }
  
  [tableView deselectRowAtIndexPath:indexPath animated:true];
}

@end
