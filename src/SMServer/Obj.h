//
//  Obj.h
//  SMServer
//
//  Created by Ian Welker on 7/6/20.
//  Copyright © 2020 Ian Welker. All rights reserved.
//

#ifndef Obj_h
#define Obj_h

@interface sender : NSObject

- (void)launchMobileSMS;
- (void)relaunchApp;
- (uid_t)setUID;
- (void)sendIPCText:(NSString *)body toAddress:(NSString *)address withAttachments:(NSArray *)paths;

@end

#endif /* Obj_h */
