// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "GameFileCacheManager.h"

#import "FoundationStringUtil.h"
#import "GameFilePtrWrapper.h"
#import "Swift.h"
#import "UICommon/GameFile.h"

#import "UICommon/GameFileCache.h"

@implementation GameFileCacheManager

+ (GameFileCacheManager*)sharedManager {
  static dispatch_once_t _onceToken = 0;
  static GameFileCacheManager* _sharedManager = nil;
  
  dispatch_once(&_onceToken, ^{
    _sharedManager = [[self alloc] init];
  });
  
  return _sharedManager;
}

- (id)init {
  if (self = [super init]) {
    self->_cache = new UICommon::GameFileCache();
    self->_cache->Load();
  }
  
  return self;
}

- (void)updateCacheWithShouldUpdateMetadata:(bool)updateMetadata {
  NSString* softwareFolder = [UserFolderUtil getSoftwareFolder];
  
  std::vector<std::string> scanPaths{ FoundationToCppString(softwareFolder) };
  
  bool cacheUpdated = self->_cache->Update(UICommon::FindAllGamePaths(scanPaths, true));
  
  if (updateMetadata) {
    cacheUpdated |= self->_cache->UpdateAdditionalMetadata();
  }
  
  if (cacheUpdated) {
    self->_cache->Save();
  }
}

- (void)rescan {
  [self updateCacheWithShouldUpdateMetadata:false];
}

- (void)rescanAndFetchMetadataWithCompletionHandler:(nullable void (^)())completion_handler {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [self updateCacheWithShouldUpdateMetadata:true];
    
    if (completion_handler) {
      completion_handler();
    }
  });
}

- (NSArray<GameFilePtrWrapper*>*)getGames {
  NSMutableArray<GameFilePtrWrapper*>* array = [[NSMutableArray alloc] init];
  self->_cache->ForEach([array](const std::shared_ptr<const UICommon::GameFile>& game) {
    GameFilePtrWrapper* wrapper = [[GameFilePtrWrapper alloc] init];
    wrapper.gameFile = game;
    
    [array addObject:wrapper];
  });
  
  return array;
}

@end
