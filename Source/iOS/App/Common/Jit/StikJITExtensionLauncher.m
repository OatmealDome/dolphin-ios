// Copyright 2025 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "StikJITExtensionLauncher.h"
#import <objc/message.h>
#import <objc/runtime.h>

@interface NSExtension : NSObject
- (nullable NSUUID*)beginRequestWithInputItems:(NSArray<NSExtensionItem*>*)items;
- (void)setRequestInterruptionBlock:(void (^)(NSUUID* requestIdentifier))block;
- (pid_t)pidForRequestIdentifier:(NSUUID*)requestIdentifier;
- (void)_kill:(int)signal;
@end

static NSString* const kStikJITListenerEndpointKey = @"DOLStikJITListenerEndpoint";

@interface StikJITListenerDelegate : NSObject <NSXPCListenerDelegate>
@property(copy, nullable) void (^onConnection)(NSXPCConnection* c);
@end

@implementation StikJITListenerDelegate
- (BOOL)listener:(NSXPCListener*)listener shouldAcceptNewConnection:(NSXPCConnection*)c {
    if (self.onConnection) self.onConnection(c);
    return YES;
}
@end

@implementation StikJITExtensionLauncher {
    __weak id<StikJITHostXPCProtocol> _host;
    NSXPCListener* _listener;
    StikJITListenerDelegate* _delegate;
    NSXPCConnection* _connection;
    NSExtension* _extension;
    NSUUID* _requestId;
    int32_t _childPID;
    BOOL _completed;
}

- (instancetype)initWithHost:(id<StikJITHostXPCProtocol>)host {
    if ((self = [super init])) { _host = host; }
    return self;
}

- (nullable NSString*)childBundleIdentifier {
    NSURL* plugins = [NSBundle mainBundle].builtInPlugInsURL;
    if (!plugins) return nil;
    NSArray<NSURL*>* items = [[NSFileManager defaultManager]
        contentsOfDirectoryAtURL:plugins
      includingPropertiesForKeys:nil
                         options:NSDirectoryEnumerationSkipsHiddenFiles
                           error:nil];
    for (NSURL* url in items) {
        if ([[url pathExtension] isEqualToString:@"appex"]) {
            NSBundle* b = [NSBundle bundleWithURL:url];
            if (b.bundleIdentifier) return b.bundleIdentifier;
        }
    }
    return nil;
}

- (nullable NSExtension*)createExtension:(NSString*)identifier error:(NSError**)error {
    Class cls = NSClassFromString(@"NSExtension");
    SEL sel = NSSelectorFromString(@"extensionWithIdentifier:excludingDisabledExtensions:error:");
    if (!cls || !class_getClassMethod(cls, sel)) return nil;
    typedef id (*Fn)(id, SEL, NSString*, BOOL, NSError**);
    return ((Fn)objc_msgSend)(cls, sel, identifier, NO, error);
}

- (void)launchWithCompletion:(void (^)(int32_t, id<StikJITRunnerXPCProtocol> _Nullable, NSError* _Nullable))completion {
    void (^complete)(int32_t, id, NSError*) = ^(int32_t pid, id runner, NSError* err) {
        if (self->_completed) return;
        self->_completed = YES;
        completion(pid, runner, err);
    };

    _delegate = [StikJITListenerDelegate new];
    _listener = [NSXPCListener anonymousListener];
    __weak typeof(self) weakSelf = self;
    _delegate.onConnection = ^(NSXPCConnection* c) {
        typeof(self) strongSelf = weakSelf;
        if (!strongSelf || strongSelf->_connection) { [c invalidate]; return; }
        strongSelf->_connection = c;
        c.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(StikJITHostXPCProtocol)];
        c.exportedObject = strongSelf->_host;
        c.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(StikJITRunnerXPCProtocol)];
        [c resume];
        id<StikJITRunnerXPCProtocol> runner = [c remoteObjectProxyWithErrorHandler:^(NSError* e) {}];
        complete(strongSelf->_childPID, runner, nil);
    };
    _listener.delegate = _delegate;
    [_listener resume];

    NSString* identifier = [self childBundleIdentifier];
    if (!identifier) {
        NSLog(@"[StikJITLauncher] no .appex found in %@", [NSBundle mainBundle].builtInPlugInsURL);
        complete(-1, nil, [NSError errorWithDomain:@"StikJITLauncher" code:1
                                          userInfo:@{NSLocalizedDescriptionKey: @"StikJIT runner .appex not found"}]);
        return;
    }
    NSLog(@"[StikJITLauncher] launching runner extension %@", identifier);

    NSError* err = nil;
    _extension = [self createExtension:identifier error:&err];
    if (!_extension) {
        NSString* reason = err.localizedDescription
            ? [NSString stringWithFormat:@"NSExtension creation failed: %@", err.localizedDescription]
            : @"NSExtension creation failed";
        NSLog(@"[StikJITLauncher] %@ (underlying: %@)", reason, err);
        complete(-1, nil, err ?: [NSError errorWithDomain:@"StikJITLauncher" code:2
                                                 userInfo:@{NSLocalizedDescriptionKey: reason}]);
        return;
    }

    if ([_extension respondsToSelector:@selector(setRequestInterruptionBlock:)]) {
        [_extension setRequestInterruptionBlock:^(NSUUID* req) {
            NSLog(@"[StikJITLauncher] runner interrupted before bootstrap (request %@)", req);
            complete(-1, nil, [NSError errorWithDomain:@"StikJITLauncher" code:3
                                              userInfo:@{NSLocalizedDescriptionKey: @"runner interrupted before bootstrap"}]);
        }];
    }

    NSExtensionItem* input = [NSExtensionItem new];
    input.userInfo = @{ kStikJITListenerEndpointKey: _listener.endpoint };

    NSError* reqErr = nil;
    SEL beginSel = NSSelectorFromString(@"beginExtensionRequestWithInputItems:error:");
    if ([_extension respondsToSelector:beginSel]) {
        typedef id (*Fn)(id, SEL, NSArray*, NSError**);
        id req = ((Fn)objc_msgSend)(_extension, beginSel, @[input], &reqErr);
        _requestId = [req isKindOfClass:[NSUUID class]] ? req : nil;
    } else {
        _requestId = [_extension beginRequestWithInputItems:@[input]];
    }
    if (!_requestId) {
        NSString* reason = reqErr.localizedDescription
            ? [NSString stringWithFormat:@"begin extension request failed: %@", reqErr.localizedDescription]
            : @"begin extension request failed";
        NSLog(@"[StikJITLauncher] %@ (underlying: %@)", reason, reqErr);
        complete(-1, nil, [NSError errorWithDomain:@"StikJITLauncher" code:4
                                          userInfo:@{NSLocalizedDescriptionKey: reason}]);
        return;
    }

    if ([_extension respondsToSelector:@selector(pidForRequestIdentifier:)]) {
        _childPID = [_extension pidForRequestIdentifier:_requestId];
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 12 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        complete(-1, nil, [NSError errorWithDomain:@"StikJITLauncher" code:5
                                          userInfo:@{NSLocalizedDescriptionKey: @"timed out waiting for runner"}]);
    });
}

- (void)invalidate {
    if (_connection) { [_connection invalidate]; _connection = nil; }
    if (_extension) {
        if (_requestId && [_extension respondsToSelector:@selector(_kill:)]) [_extension _kill:9];
        _extension = nil;
    }
    if (_listener) { _listener.delegate = nil; [_listener invalidate]; _listener = nil; }
    _delegate = nil;
}

@end
