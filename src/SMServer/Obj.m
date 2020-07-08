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

-(void)launchMobileSMS {
    //[[UIApplication sharedApplication] launchApplicationWithIdentifier:@"com.apple.MobileSMS" suspended:YES];
    
    MRYIPCCenter* center = [MRYIPCCenter centerNamed:@"com.ianwelker.smserverLaunch"];
    [center callExternalMethod:@selector(launchSMS) withArguments:nil];
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
