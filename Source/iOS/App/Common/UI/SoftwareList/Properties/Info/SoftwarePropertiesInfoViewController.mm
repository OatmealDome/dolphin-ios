// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "SoftwarePropertiesInfoViewController.h"

#import "UICommon/GameFile.h"

#import "FoundationStringUtil.h"
#import "GameFilePtrWrapper.h"
#import "LocalizationUtil.h"

@interface SoftwarePropertiesInfoViewController ()

@end

@implementation SoftwarePropertiesInfoViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  const UICommon::GameFile* gameFile = self.gameFileWrapper.gameFile.get();
  
  const std::string gameNameCpp = gameFile->GetInternalName();
  
  NSString* gameName;
  
  if (!gameNameCpp.empty()) {
    gameName = CppToFoundationString(gameNameCpp);
  } else {
    gameName = DOLCoreLocalizedString(@"Unknown");
  }
  
  const DiscIO::Platform platform = gameFile->GetPlatform();
  const bool isDiscBased = platform == DiscIO::Platform::GameCubeDisc || platform == DiscIO::Platform::WiiDisc;
  
  NSString* internalName;
  
  if (isDiscBased) {
    NSString* formatStr = DOLCoreLocalizedStringWithArgs(@"%1 (Disc %2, Revision %3)", @"@", @"d", @"d");
    internalName = [NSString stringWithFormat:formatStr, gameName, gameFile->GetDiscNumber() + 1, gameFile->GetRevision()];
  } else {
    NSString* formatStr = DOLCoreLocalizedStringWithArgs(@"%1 (Revision %3)", @"@", @"", @"d");
    internalName = [NSString stringWithFormat:formatStr, gameName, gameFile->GetRevision()];
  }
  
  self.nameLabel.text = internalName;
  
  NSString* gameId = CppToFoundationString(gameFile->GetGameID());
  
  if (const u64 titleId = gameFile->GetTitleID()) {
    gameId = [gameId stringByAppendingString:[NSString stringWithFormat:@" (%016llx)", titleId]];
  }
  
  self.idLabel.text = gameId;
  
  self.countryLabel.text = CppToFoundationString(DiscIO::GetName(gameFile->GetCountry(), true));
  
  self.makerLabel.text = CppToFoundationString(gameFile->GetMaker(UICommon::GameFile::Variant::LongAndNotCustom));
  
  const std::string apploaderDate = gameFile->GetApploaderDate();
  if (!apploaderDate.empty()) {
    self.apploaderLabel.text = CppToFoundationString(apploaderDate);
  } else {
    self.apploaderLabel.text = @"";
  }
}

@end
