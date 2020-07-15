//
//  Obj.h
//  SMServer
//
//  Created by Ian Welker on 7/6/20.
//  Copyright © 2020 Ian Welker. All rights reserved.
//

#ifndef Obj_h
#define Obj_h

/*@interface IPCTextWatcher : NSObject

@property (nonatomic, strong) void(^completion)(void);
-(void)handleReceivedTextWithCallback;

@end*/

@interface Sender : NSObject

//@property (nonatomic, strong) void(^call)(void);
//@property (nonatomic, strong) IPCTextWatcher* watcher;

//- (id)initWithCallback:(void(^)(void))call;
- (void)launchMobileSMS;
- (void)relaunchApp;
- (uid_t)setUID;
- (void)sendIPCText:(NSString *)body toAddress:(NSString *)address withAttachments:(NSArray *)paths;

@end

#endif /* Obj_h */
