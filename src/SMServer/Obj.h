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
- (void)sendIPCText:(NSString *)body toAddress:(NSString *)address;
//- (void)sendIPCAttachment:(NSString *)body toAddress:(NSString *)address withAttachment:(NSString *)path;

@end

/*@interface UIApplication
- (_Bool)launchApplicationWithIdentifier:(id)arg1 suspended:(_Bool)arg2;
+ (id)sharedApplication;
@end*/

#endif /* Obj_h */
