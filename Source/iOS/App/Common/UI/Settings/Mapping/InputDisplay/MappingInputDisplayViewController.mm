// Copyright 2024 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "MappingInputDisplayViewController.h"

#import "InputCommon/ControllerInterface/ControllerInterface.h"

#import "FoundationStringUtil.h"
#import "MappingInputDisplayInputCell.h"

@interface MappingInputDisplayViewController ()

@end

@implementation MappingInputDisplayViewController {
  std::shared_ptr<ciface::Core::Device> _device;
  NSTimer* _timer;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  ciface::Core::DeviceQualifier qualifier;
  qualifier.FromString(FoundationToCppString(_deviceStr));
  
  _device = g_controller_interface.FindDevice(qualifier);
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 / 60.0 target:self selector:@selector(updateInputCells) userInfo:nil repeats:true];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
  if (_timer != nil) {
    [_timer invalidate];
    _timer = nil;
  }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
  return _device == nullptr ? 0 : _device->Inputs().size();
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  MappingInputDisplayInputCell* cell = [tableView dequeueReusableCellWithIdentifier:@"InputCell" forIndexPath:indexPath];
  
  auto input = _device->Inputs()[indexPath.row];
  
  cell.inputLabel.text = CppToFoundationString(input->GetName());
  cell.valueLabel.text = [NSString stringWithFormat:@"%.2f", input->GetState()];
  
  return cell;
}

- (void)updateInputCells {
  [self.tableView reloadData];
}

@end
