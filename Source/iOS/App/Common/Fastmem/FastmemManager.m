// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "FastmemManager.h"

#import <mach/mach.h>

@interface FastmemManager()

@property (readwrite) bool fastmemAvailable;

@end

@implementation FastmemManager

const size_t DOLFastmemRegionSize = 0x400000000;

+ (FastmemManager*)shared {
  static FastmemManager* sharedInstance = nil;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });

  return sharedInstance;
}

- (id)init {
  if (self = [super init]) {
    vm_address_t addr = 0;
    kern_return_t retval = vm_allocate(mach_task_self(), &addr, DOLFastmemRegionSize, VM_FLAGS_ANYWHERE);
    
    self.fastmemAvailable = retval == KERN_SUCCESS;
    
    if (self.fastmemAvailable) {
      vm_deallocate(mach_task_self(), addr, DOLFastmemRegionSize);
    }
  }
  
  return self;
}

@end
