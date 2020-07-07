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

- (void)sendText:(NSString *)body toAddress:(NSString *)address;
- (void)sendIPCText:(NSString *)body toAddress:(NSString *)address;

@end

#endif /* Obj_h */
