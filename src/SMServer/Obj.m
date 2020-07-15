//
//  Obj.m
//  SMServer
//
//  Created by Ian Welker on 5/13/20.
//  Copyright © 2020 Ian Welker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MRYIPCCenter.h"

#import "Obj.h"

/*@implementation IPCTextWatcher {
    MRYIPCCenter* _center;
}

+(void)load {
    [self sharedInstance:nil];
}

+(instancetype)sharedInstance:(void(^)(void))callback {
    static dispatch_once_t onceToken = 0;
    __strong static IPCTextWatcher* sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init:callback];
    });
    return sharedInstance;
}

-(instancetype)init:(void(^)(void))callback {
    if ((self = [super init])) {
        _center = [MRYIPCCenter centerNamed:@"com.ianwelker.smserverHandleText"];
        [_center addTarget:self action:@selector(handleReceivedTextWithCallback)];
        _completion = callback;
    }
    return self;
}

-(void)handleReceivedTextWithCallback {
    _completion();
}

@end*/

@implementation Sender

/*- (id)initWithCallback:(void(^)(void))call {
    self = [super init];
    if (self) {
        _call = call;
        _watcher = [IPCTextWatcher sharedInstance:_call];
    }
    return self;
}*/

- (void)relaunchApp {
    
    MRYIPCCenter* center = [MRYIPCCenter centerNamed:@"com.ianwelker.smserverLaunch"];
    [center callExternalMethod:@selector(relaunchSMServer) withArguments:nil];
    
}

- (void)launchMobileSMS {
    
    NSLog(@"SMServer_app: Entered obj-c func, launching MobileSMS");
    
    MRYIPCCenter* center = [MRYIPCCenter centerNamed:@"com.ianwelker.smserverLaunch"];
    [center callExternalMethod:@selector(launchSMS) withArguments:nil];
    
    NSLog(@"SMServer_app: Called IPC to launch MobileSMS");
}

- (uid_t)setUID {
    setuid(0);
    
    return getuid();
}

- (void)sendIPCText:(NSString *)body toAddress:(NSString *)address withAttachments:(NSArray *)paths {
    
    MRYIPCCenter* center = [MRYIPCCenter centerNamed:@"com.ianwelker.smserver"];
    [center callExternalMethod:@selector(sendText:) withArguments:@{@"body": body, @"address": address, @"attachment": paths}];
    
}

@end

