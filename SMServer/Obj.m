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

@interface CTMessageCenter

+(id)sharedMessageCenter;
-(BOOL)sendSMSWithText:(id)arg1 serviceCenter:(id)arg2 toAddress:(id)arg3;
-(BOOL)sendSMSWithText:(id)arg1 serviceCenter:(id)arg2 toAddress:(id)arg3 withMoreToFollow:(bool)arg4 withID:(unsigned int)arg5;

@end

@implementation obj_class

-(void) loadBundle {
    NSBundle *ctm = [NSBundle bundleWithPath:@"/System/Library/Frameworks/CoreTelephony.framework"];
    [ctm load];
    
    Class CTMC = NSClassFromString(@"CTMessageCenter");
    
    [[CTMC sharedMessageCenter] sendSMSWithText:@"Hey! This is a test. If you got it and didn't expect to, just let me know. Thank you :)" serviceCenter:nil toAddress:@"+15203106053"];
    
}


@end
