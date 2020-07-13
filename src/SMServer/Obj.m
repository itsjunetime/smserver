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

@implementation sender

- (void)relaunchApp {
    
    MRYIPCCenter* center = [MRYIPCCenter centerNamed:@"com.ianwelker.smserverLaunch"];
    [center callExternalMethod:@selector(relaunchSMServer) withArguments:nil];
    
}

- (void)launchMobileSMS {
    
    MRYIPCCenter* center = [MRYIPCCenter centerNamed:@"com.ianwelker.smserverLaunch"];
    [center callExternalMethod:@selector(launchSMS) withArguments:nil];
}

- (uid_t)setUID {
    setuid(0);
    
    return getuid();
}

- (void)sendIPCText:(NSString *)body toAddress:(NSString *)address withAttachments:(NSArray *)paths {
    
    MRYIPCCenter* center = [MRYIPCCenter centerNamed:@"com.ianwelker.smserver"];
    
    [center callExternalMethod:@selector(sendAttachment:) withArguments:@{@"body": body, @"address": address, @"attachment": paths}];
    
}

@end
