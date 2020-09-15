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

@interface IWSSender : NSObject

- (void)launchMobileSMS;
- (uid_t)setUID;
- (void)sendIPCText:(NSString *)body toAddress:(NSString *)address withAttachments:(NSArray *)paths;
- (void)markConvoAsRead:(NSString *)chat_id;
- (void)sendReaction:(NSNumber *)reaction forGuid:(NSString *)guid inChat:(NSString *)chat;

@end

#endif /* Obj_h */
