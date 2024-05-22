// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

#ifdef __cplusplus
namespace UICommon {
  class GameFileCache;
}

typedef UICommon::GameFileCache GameFileCache;
#else
typedef void GameFileCache;
#endif

@class GameFilePtrWrapper;

NS_ASSUME_NONNULL_BEGIN

@interface GameFileCacheManager : NSObject {
  GameFileCache* _cache;
}

+ (GameFileCacheManager*)sharedManager;

- (void)rescan;
- (void)rescanAndFetchMetadataWithCompletionHandler:(nullable void (^)(void))completion_handler;

- (NSArray<GameFilePtrWrapper*>*)getGames;

@end

NS_ASSUME_NONNULL_END
