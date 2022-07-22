// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>

#import <string>
#import <vector>

#import "Core/HW/WiimoteEmu/WiimoteEmu.h"

namespace ciface {
namespace Core {
class DeviceContainer;
class DeviceQualifier;
}

namespace MappingCommon {
enum class Quote;
}
}

@class UIViewController;

NS_ASSUME_NONNULL_BEGIN

@interface MappingUtil : NSObject

+ (NSString*)getLocalizedStringForWiimoteExtension:(WiimoteEmu::ExtensionNumber)extension;

+ (void)detectExpressionWithDefaultDevice:(const ciface::Core::DeviceQualifier&)defaultDevice
                               allDevices:(bool)allDevices
                                    quote:(ciface::MappingCommon::Quote)quote
                           viewController:(UIViewController*)viewController
                                 callback:(void (^)(std::string))callback;

@end

NS_ASSUME_NONNULL_END
