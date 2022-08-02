// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "JitManager+JitStreamer.h"

@implementation JitManager (JitStreamer)

- (void)acquireJitByJitStreamer {
  NSString* urlString = [NSString stringWithFormat:@"http://69.69.0.1/attach/%ld/", (long)getpid()];
    
  NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
  [request setHTTPMethod:@"POST"];
  [request setHTTPBody:[@"" dataUsingEncoding:NSUTF8StringEncoding]];
  
  [[[NSURLSession sharedSession] dataTaskWithRequest:request] resume];
}

@end
