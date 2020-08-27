#ifndef Obj_h
#define Obj_h

@interface IPCTextWatcher : NSObject

@property (copy) void(^setTexts)(NSString *);
@property (copy) void(^setBattery)(void);
+ (instancetype)sharedInstance;
- (instancetype)init;
- (void)handleReceivedTextWithCallback:(NSString *)chat_id;
- (void)handleBatteryChanged;

@end

@interface Sender : NSObject

- (void)launchMobileSMS;
- (void)relaunchApp;
- (uid_t)setUID;
- (void)sendIPCText:(NSString *)body toAddress:(NSString *)address withAttachments:(NSArray *)paths;
- (void)markConvoAsRead:(NSString *)chat_id;

@end

@interface CPDistributedMessagingCenter
+ (id)centerNamed:(id)arg1;
@end

#endif /* Obj_h */
