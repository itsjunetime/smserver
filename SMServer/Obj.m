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

@protocol CKConversation

- (void)sendMessage:(id)arg1 newComposition:(bool)arg2;
- (void)sendMessage:(id)arg1 onService:(id)arg2 newComposition:(bool)arg3;
- (void)setChat:(id)arg1;

@end

@protocol IMChatRegistration

- (void)_chat:(id)arg1 sendMessage:(id)arg2;

@end

@interface CTMessageCenter

+(id)sharedMessageCenter;
-(BOOL)sendSMSWithText:(id)arg1 serviceCenter:(id)arg2 toAddress:(id)arg3;

@end

@implementation obj_class

-(void) loadBundle {
    /*NSBundle *imb = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/IMDaemonCore.framework"];
    BOOL success = [imb load];
    
    Class IMServiceSession = NSClassFromString(@"IMServiceSession");*/
    /*id si = [IMServiceSession valueForKey:@"allServiceSessions"];
    
    NSLog(@"%lu", (sizeof si));
    
    for (int i = 0; i < sizeof(si); ++i) {
        NSLog(@"thing: %@", [si[i] valueForKey:@"accountID"]);
    }
    
    if (success) {
        NSLog(@"succesafsd!!!");
    } else {
        NSLog(@"nah bruh :(((");
    }*/
    
    /*NSNumber *id = @(25);
    
    [IMServiceSession sendMessage:@"This is a test message. Sorry if you're getting it and didn't expect to; just let me know :)" toChat:id style:45];
    
    if ([IMServiceSession isActive]) {
        NSLog(@"Yup, weacisd");
    } else {
        NSLog(@"noppoodo");
    }*/
    
    /*NSBundle *ckb = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/ChatKit.framework"];
    BOOL ck_success = [ckb load];

    Class CKConversation = NSClassFromString(@"CKConversation");
    NSLog(@"max: %@", [CKConversation valueForKey:@"_iMessage_maxAttachmentCount"]);
    if (ck_success) {
        NSLog(@"Printing success for ck");
    } else {
        NSLog(@"No success for ck");
    }*/
    
    NSBundle *ctm = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/IMCore.framework"]; ///Change to CTMessageCenter
    [ctm load];
    
    Class CTMessageCenter = NSClassFromString(@"CTMessageCenter");
    //id si = [CTMessageCenter valueForKey:@"sharedMessageCenter"];
    
    [[CTMessageCenter sharedMessageCenter] sendSMSWithText:@"Hey! This is a test. If you got it and didn't expect to, just let me know. Thank you :)" serviceCenter:nil toAddress:@"5203106053"];
    /*id *sic = [IMChatRegistry valueForKey:@"sharedInstance"];
    
    [sic _chat:@25 sendMessage:@"This is a test message. Sorry if you're getting it and didn't expect to; just let me know :)"];*/
    
}


@end
