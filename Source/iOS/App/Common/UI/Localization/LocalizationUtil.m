// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "LocalizationUtil.h"

@implementation LocalizationUtil

+ (NSString*)setFormatSpecifiersOnQString:(NSString*)str, ... {
  NSString* currentString = str;
  
  va_list args;
  va_start(args, str);
  
  id arg;
  int argCount = 0;
  
  while ((arg = va_arg(args, id)) != nil) {
    argCount++;
    
    NSString* toReplace = [NSString stringWithFormat:@"%%%d", argCount];
    NSString* replaceWith = [NSString stringWithFormat:@"%%%d$%@", argCount, arg];
    currentString = [currentString stringByReplacingOccurrencesOfString:toReplace withString:replaceWith];
  }
  
  va_end(args);
  
  return currentString;
}


@end
