// Copyright 2025 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <objc/runtime.h>

static void DOLStikJITAllowXPCClass(id self, SEL _cmd, id cls, id key, BOOL allowingInvocations) {}

__attribute__((used, visibility("default")))
int NSExtensionMain(int argc, char* argv[]) {
    NSLog(@"[JITEnabler] NSExtensionMain entered");

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    Method method = class_getInstanceMethod(
        NSClassFromString(@"NSXPCDecoder"),
        @selector(_validateAllowedClass:forKey:allowingInvocations:));
    if (method) {
        method_setImplementation(method, (IMP)DOLStikJITAllowXPCClass);
    }
#pragma clang diagnostic pop

    int (*originalNSExtensionMain)(int, char**) =
        (int (*)(int, char**))dlsym(RTLD_NEXT, "NSExtensionMain");
    return originalNSExtensionMain(argc, argv);
}
