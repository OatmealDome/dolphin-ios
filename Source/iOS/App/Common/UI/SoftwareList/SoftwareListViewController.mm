// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "SoftwareListViewController.h"

#import "EmulationBootParameter.h"
#import "EmulationViewController.h"
#import "FoundationStringUtil.h"
#import "GameFileCacheManager.h"
#import "GameFilePtrWrapper.h"
#import "SoftwarePropertiesViewController.h"
#import "Swift.h"
#import "WiiSystemUpdateViewController.h"

#import "UICommon/GameFile.h"

@interface SoftwareListViewController ()

@end

@implementation SoftwareListViewController {
  NSString* _wiiUpdateSource;
  bool _wiiUpdateIsOnline;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self->_gameFiles = [[GameFileCacheManager sharedManager] getGames];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  [self reloadGameFiles];
}

- (void)reloadGameFiles {
  [[GameFileCacheManager sharedManager] rescanAndFetchMetadataWithCompletionHandler:^{
    dispatch_async(dispatch_get_main_queue(), ^{
      self->_gameFiles = [[GameFileCacheManager sharedManager] getGames];
      [self.collectionView reloadData];
    });
  }];
}

- (void)loadGameFile:(GameFilePtrWrapper*)gameFileWrapper {
  std::shared_ptr<const UICommon::GameFile> game = gameFileWrapper.gameFile;
  
  std::shared_ptr<const UICommon::GameFile> second_game = nullptr;
  std::shared_ptr<const UICommon::GameFile> match_without_revision = nullptr;
  
  if (DiscIO::IsDisc(game->GetPlatform())) {
    for (GameFilePtrWrapper* otherWrapper in self->_gameFiles) {
      std::shared_ptr<const UICommon::GameFile> other_game = otherWrapper.gameFile;
      
      if (game->GetGameID() == other_game->GetGameID() &&
          game->GetDiscNumber() != other_game->GetDiscNumber()) {
        if (game->GetRevision() == other_game->GetRevision()) {
          second_game = other_game;
          break;
        } else {
          match_without_revision = other_game;
        }
      }
    }
  }
  
  if (second_game == nullptr) {
    second_game = match_without_revision;
  }
  
  _bootParameter = [[EmulationBootParameter alloc] init];
  _bootParameter.bootType = EmulationBootTypeFile;
  _bootParameter.path = CppToFoundationString(game->GetFilePath());
  _bootParameter.secondPath = second_game != nullptr ? CppToFoundationString(second_game->GetFilePath()) : nil;
  _bootParameter.isNKit = gameFileWrapper.gameFile->IsNKit();
  
  [self performSegueWithIdentifier:@"emulation" sender:nil];
}

- (void)loadGameCubeIPLForRegion:(DiscIO::Region)region {
  _bootParameter = [[EmulationBootParameter alloc] init];
  _bootParameter.bootType = EmulationBootTypeGCIPL;
  _bootParameter.iplRegion = region;
  
  [self performSegueWithIdentifier:@"emulation" sender:nil];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView {
  return 1;
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
  return self->_gameFiles.count;
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath {
  SoftwareListCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"softwareCell" forIndexPath:indexPath];
  GameFilePtrWrapper* gameFileWrapper = [self->_gameFiles objectAtIndex:indexPath.item];
  
  NSString* gameName = CppToFoundationString(gameFileWrapper.gameFile->GetName(UICommon::GameFile::Variant::LongAndPossiblyCustom));
  
  const UICommon::GameCover& cover = gameFileWrapper.gameFile->GetCoverImage();
  
  UIImage* image;
  if (cover.buffer.empty()) {
    image = [UIImage imageNamed:@"NoCover"];
  } else {
    NSData* data = [NSData dataWithBytes:cover.buffer.data() length:cover.buffer.size()];
    image = [UIImage imageWithData:data];
  }
  
  cell.imageView.image = image;
  cell.nameLabel.text = gameName;
  
  return cell;
}

- (void)collectionView:(UICollectionView*)collectionView didSelectItemAtIndexPath:(NSIndexPath*)indexPath {
  GameFilePtrWrapper* gameFileWrapper = [self->_gameFiles objectAtIndex:indexPath.item];
  
  [self loadGameFile:gameFileWrapper];
}

#pragma mark <UICollectionViewDelegateFlowLayout>

- (CGSize)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath*)indexPath {
  const CGFloat cellsPerRow = 3.f;
  const CGFloat cellSpacing = 4.f;
  const CGFloat cellHeight = 218.f;
  
  CGFloat totalSpacing = ((cellsPerRow - 1) * cellSpacing);
  return CGSizeMake((collectionView.bounds.size.width - totalSpacing) / cellsPerRow, cellHeight);
}

#pragma mark Segue

- (void)performSegueForWiiUpdateWithSource:(NSString*)source isOnline:(bool)online {
  _wiiUpdateSource = source;
  _wiiUpdateIsOnline = online;
  
  [self performSegueWithIdentifier:@"wiiUpdate" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
  if ([segue.identifier isEqualToString:@"emulation"]) {
    UINavigationController* navigationController = segue.destinationViewController;
    EmulationViewController* viewController = navigationController.viewControllers[0];
    
    viewController.bootParameter = _bootParameter;
  } else if ([segue.identifier isEqualToString:@"wiiUpdate"]) {
    WiiSystemUpdateViewController* updateController = segue.destinationViewController;
    
    updateController.updateSource = _wiiUpdateSource;
    updateController.isOnlineUpdate = _wiiUpdateIsOnline;
  } else if ([segue.identifier isEqualToString:@"properties"]) {
    UINavigationController* navigationController = segue.destinationViewController;
    SoftwarePropertiesViewController* propertiesController = navigationController.viewControllers[0];
    
    propertiesController.gameFileWrapper = _selectedFile;
  }
}

@end
