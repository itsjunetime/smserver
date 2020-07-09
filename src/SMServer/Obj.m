//
//  Obj.m
//  SMServer
//
//  Created by Ian Welker on 5/13/20.
//  Copyright © 2020 Ian Welker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MRYIPCCenter.h"
//#include "CPDistributedMessagingCenter.h"
//#include "rocketbootstrap.h"

#import "Obj.h"

@implementation sender

-(uid_t)launchMobileSMS {
    //[[UIApplication sharedApplication] launchApplicationWithIdentifier:@"com.apple.MobileSMS" suspended:YES];
    
    setuid(0);
    
    
    
    MRYIPCCenter* center = [MRYIPCCenter centerNamed:@"com.ianwelker.smserverLaunch"];
    [center callExternalMethod:@selector(launchSMS) withArguments:nil];
    
    /*NSLog(@"uid now %d", getuid());
    CPDistributedMessagingCenter *messageCenter = [CPDistributedMessagingCenter centerNamed:@"com.jakeashacks.rootme"];
    rocketbootstrap_distributedmessagingcenter_apply(messageCenter);
    [messageCenter sendMessageAndReceiveReplyName:@"rootme" userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%d", getpid()] forKey:@"pid"]];
    NSLog(@"uid after %d", getuid());*/
    
    return getuid();
}

- (void)sendIPCText:(NSString *)body toAddress:(NSString *)address {

    MRYIPCCenter* center = [MRYIPCCenter centerNamed:@"com.ianwelker.smserver"];
    
    [center callExternalMethod:@selector(handleText:) withArguments:@{@"body": body, @"address": address}];
}

/*- (void)sendIPCAttachment:(NSString *)body toAddress:(NSString *)address withAttachment:(NSString *)path {
    
    MRYIPCCenter* center = [MRYIPCCenter centerNamed:@"com.ianwelker.smserver"];
    
    [center callExternalMethod:@selector(sendAttachment:) withArguments:@{@"body": body, @"address": address, @"attachment": path}];
    
}*/

@end
