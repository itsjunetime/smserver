#ifndef Obj_h
#define Obj_h

@interface IPCTextWatcher : NSObject

@property (copy) void(^setTexts)(NSString *);
@property (copy) void(^setTyping)(NSDictionary *);
@property (copy) void(^sentTapback)(int, NSString *);
+ (instancetype)sharedInstance;
- (instancetype)init;
- (void)handleReceivedTextWithCallback:(NSString *)chat_id;
- (void)handlePartyTypingWithCallback:(NSDictionary *)vals;
- (void)handleSentTapbackWithCallback:(NSDictionary *)vals;

@end

@interface IWSSender : NSObject

- (id)init;
- (void)launchMobileSMS;
- (BOOL)sendIPCText:(NSString *)body withSubject:(NSString *)subject toAddress:(NSString *)address withAttachments:(NSArray *)paths;
- (BOOL)markConvoAsRead:(NSString *)chat_id;
- (BOOL)sendTapback:(NSNumber *)tapback forGuid:(NSString *)guid inChat:(NSString *)chat;
- (void)sendTyping:(BOOL)isTyping forChat:(NSString *)chat;
- (BOOL)removeObject:(NSString *)chat text:(NSString *)text;
//- (NSArray *)getPinnedChats;

@end

/*
@interface IMPinnedConversationsController
+ (id)sharedInstance;
- (NSOrderedSet *)pinnedConversationIdentifierSet;
@end

@interface IMDaemonController
+ (id)sharedController;
- (BOOL)connectToDaemon;
@end
*/


@interface IMChat
- (void)markAllMessagesAsRead;
- (void)setLocalUserIsTyping:(BOOL)arg1;
@end

@interface IMChatRegistry
+ (id)sharedInstance;
- (IMChat *)existingChatWithChatIdentifier:(NSString *)chat_id;
@end

#endif /* Obj_h */
