// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "SoftwarePropertiesViewController.h"

#import "UICommon/GameFile.h"

#import "ActionReplayCodeViewController.h"
#import "FoundationStringUtil.h"
#import "GameFilePtrWrapper.h"
#import "GeckoCodeViewController.h"
#import "SoftwarePropertiesInfoViewController.h"

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

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
  if ([segue.identifier isEqualToString:@"info"]) {
    SoftwarePropertiesInfoViewController* infoController = segue.destinationViewController;
    infoController.gameFileWrapper = self.gameFileWrapper;
  } else if ([segue.identifier isEqualToString:@"gecko"]) {
    GeckoCodeViewController* geckoController = segue.destinationViewController;
    geckoController.gameId = self.gameFileWrapper.gameFile->GetGameID();
    geckoController.gametdbId = self.gameFileWrapper.gameFile->GetGameTDBID();
    geckoController.revision = self.gameFileWrapper.gameFile->GetRevision();
  } else if ([segue.identifier isEqualToString:@"ar"]) {
    ActionReplayCodeViewController* arController = segue.destinationViewController;
    arController.gameId = self.gameFileWrapper.gameFile->GetGameID();
    arController.revision = self.gameFileWrapper.gameFile->GetRevision();
  }
}

@end
