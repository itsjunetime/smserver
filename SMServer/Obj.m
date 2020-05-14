//
//  Obj.m
//  SMServer
//
//  Created by Ian Welker on 5/13/20.
//  Copyright © 2020 Ian Welker. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface obj_class : NSObject

-(void) loadBundle;

@end

@protocol IMServiceSession

- (void)sendMessage:(id)arg1 toChat:(id)arg2 style:(unsigned char)arg3;
- (BOOL)isActive;

@end

@implementation obj_class

-(void) loadBundle {
    NSBundle *b = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/IMDaemonCore.framework"];
    BOOL success = [b load];
    
    Class IMServiceSession = NSClassFromString(@"IMServiceSession");
    id si = [IMServiceSession valueForKey:@"allServiceSessions"];
    
    NSLog(@"%lu", (sizeof si));
    
    for (int i = 0; i < sizeof(si); ++i) {
        NSLog(@"thing: %@", [si[i] valueForKey:@"accountID"]);
    }
    
    if (success) {
        NSLog(@"succesafsd!!!");
    } else {
        NSLog(@"nah bruh :(((");
    }
    
    NSNumber *id = @(25);
    
    [IMServiceSession sendMessage:@"This is a test message. Sorry if you're getting it and didn't expect to; just let me know :)" toChat:id style:45];
    
    if ([IMServiceSession isActive]) {
        NSLog(@"Yup, weacisd");
    } else {
        NSLog(@"noppoodo");
    }
}

@end
