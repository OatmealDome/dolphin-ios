// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

#import <memory>

namespace UICommon {
class GameFile;
}

NS_ASSUME_NONNULL_BEGIN

@interface GameFilePtrWrapper : NSObject

@property (nonatomic, assign) std::shared_ptr<const UICommon::GameFile> gameFile;

@end

NS_ASSUME_NONNULL_END
