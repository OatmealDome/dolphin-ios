// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>

NSString* const DOLImportFileFinishedNotification = @"DOLImportFileFinishedNotification";

NS_ASSUME_NONNULL_BEGIN

@interface ImportFileManager : NSObject

+ (ImportFileManager*)shared;

- (void)importFileAtUrl:(NSURL*)url;

@end

NS_ASSUME_NONNULL_END
