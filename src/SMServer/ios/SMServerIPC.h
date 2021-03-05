#ifndef SMServerIPC_h
#define SMServerIPC_h

@interface SMServerIPC : NSObject
- (NSNumber *)sendText:(NSDictionary *)vals;
- (NSNumber *)setAllAsRead:(NSString *)chat;
- (NSNumber *)sendTapback:(NSDictionary *)vals;
- (NSArray *)getPinnedChats;
- (NSNumber *)delete:(NSDictionary *)vals;
@end

#endif /* SMServerIPC_h */
