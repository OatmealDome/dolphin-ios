// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <UIKit/UIKit.h>

@class EmulationBootParameter;
@class GameFilePtrWrapper;

NS_ASSUME_NONNULL_BEGIN

@interface SoftwareListViewController : UICollectionViewController<UICollectionViewDelegateFlowLayout> {
  NSArray<GameFilePtrWrapper*>* _gameFiles;
  GameFilePtrWrapper* _selectedFile;
  EmulationBootParameter* _bootParameter;
}

- (void)reloadGameFiles;

- (void)performSegueForWiiUpdateWithSource:(NSString*)source isOnline:(bool)online;

@end

NS_ASSUME_NONNULL_END
