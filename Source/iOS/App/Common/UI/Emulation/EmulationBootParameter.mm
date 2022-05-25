// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "EmulationBootParameter.h"

#import "Core/Boot/Boot.h"

#import "FoundationStringUtil.h"

@implementation EmulationBootParameter

- (std::unique_ptr<BootParameters>) generateDolphinBootParameter {
  std::unique_ptr<BootParameters> boot;
  
  if (self.bootType == EmulationBootTypeFile)
  {
    boot = BootParameters::GenerateFromFile(FoundationToCppString(self.path), BootSessionData());
  }
  else
  {
    // TODO: GCIPL and NANDTitle
    @throw [NSException exceptionWithName:@"UnsupportedBootTypeException" reason:@"Specified EmulationBootType not supported at this time" userInfo:nil];
  }
  
  return boot;
}

@end
