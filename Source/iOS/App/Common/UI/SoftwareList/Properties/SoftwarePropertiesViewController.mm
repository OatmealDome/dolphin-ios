// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "SoftwarePropertiesViewController.h"

#import "UICommon/GameFile.h"

#import "FoundationStringUtil.h"
#import "GameFilePtrWrapper.h"

@interface SoftwarePropertiesViewController ()

@end

@implementation SoftwarePropertiesViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.navigationItem.title = CppToFoundationString(self.gameFileWrapper.gameFile->GetGameID());
}

- (IBAction)donePressed:(id)sender {
  [self.navigationController dismissViewControllerAnimated:true completion:nil];
}

@end
