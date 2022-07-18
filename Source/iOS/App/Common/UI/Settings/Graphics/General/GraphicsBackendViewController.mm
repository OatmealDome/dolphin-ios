// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "GraphicsBackendViewController.h"

#import "Core/Config/MainSettings.h"

#import "VideoCommon/VideoBackendBase.h"

#import "FoundationStringUtil.h"
#import "GraphicsBackendCell.h"
#import "LocalizationUtil.h"

@interface GraphicsBackendViewController ()

@end

@implementation GraphicsBackendViewController {
  NSInteger _lastSelected;
  NSArray<NSString*>* _localizedBackends;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  NSMutableArray<NSString*>* localizedBackends = [[NSMutableArray alloc] init];
  
  const auto currentBackend = Config::Get(Config::MAIN_GFX_BACKEND);
  
  const auto& backends = VideoBackendBase::GetAvailableBackends();
  for (size_t i = 0; i < backends.size(); i++) {
    const auto& backend = backends[i];
    
    if (backend->GetName() == currentBackend) {
      _lastSelected = i;
    }
    
    [localizedBackends addObject:DOLCoreLocalizedString(CppToFoundationString(backend->GetDisplayName()))];
  }
  
  _localizedBackends = localizedBackends;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
  return [_localizedBackends count];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  GraphicsBackendCell* cell = [tableView dequeueReusableCellWithIdentifier:@"BackendCell" forIndexPath:indexPath];
  
  cell.backendLabel.text = [_localizedBackends objectAtIndex:indexPath.row];
  
  if (indexPath.row == _lastSelected) {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  } else {
    cell.accessoryType = UITableViewCellAccessoryNone;
  }
  
  return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  void (^setBackend)(const std::string&) = ^void(const std::string& backendName) {
    Config::SetBaseOrCurrent(Config::MAIN_GFX_BACKEND, backendName);

    GraphicsBackendCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    GraphicsBackendCell* oldCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self->_lastSelected inSection:0]];
    oldCell.accessoryType = UITableViewCellAccessoryNone;
    
    self->_lastSelected = indexPath.row;
  };
  
  if (_lastSelected != indexPath.row) {
    const auto& backend = VideoBackendBase::GetAvailableBackends()[indexPath.row];
    
    auto warningMessage = backend->GetWarningMessage();
    if (warningMessage) {
      NSString* localizedMessage = DOLCoreLocalizedString(CppToFoundationString(warningMessage.value()));
      
      UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Confirm backend change" message:localizedMessage preferredStyle:UIAlertControllerStyleAlert];
      [alert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
      [alert addAction:[UIAlertAction actionWithTitle:DOLCoreLocalizedString(@"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction*) {
        dispatch_async(dispatch_get_main_queue(), ^{
          setBackend(backend->GetName());
        });
      }]];
      
      [self presentViewController:alert animated:true completion:nil];
    } else {
      setBackend(backend->GetName());
    }
  }
  
  [tableView deselectRowAtIndexPath:indexPath animated:true];
}


@end
