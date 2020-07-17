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

@implementation IPCTextWatcher {
    MRYIPCCenter* _center;
}

+(void)load {
    [self sharedInstance];
}

+(instancetype)sharedInstance {
    static dispatch_once_t onceToken = 0;
    __strong static IPCTextWatcher* sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

-(instancetype)init {
    if ((self = [super init])) {
        _center = [MRYIPCCenter centerNamed:@"com.ianwelker.smserverHandleText"];
        [_center addTarget:self action:@selector(handleReceivedTextWithCallback:)];
    }
    return self;
}

-(void)handleReceivedTextWithCallback:(NSString *)chat_id {
    _setTexts(chat_id);
}

@end

@implementation Sender


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

