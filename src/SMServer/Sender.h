#ifndef Obj_h
#define Obj_h

@interface IPCTextWatcher : NSObject

@property (copy) void(^setTexts)(NSString *);
@property (copy) void(^setTyping)(NSString *);
@property (copy) void(^sentTapback)(int, NSString *);
+ (instancetype)sharedInstance;
- (instancetype)init;
- (void)handleReceivedTextWithCallback:(NSString *)chat_id;
- (void)handlePartyTypingWithCallback:(NSString *)chat_id;
- (void)handleSentTapbackWithCallback:(NSDictionary *)vals;

@end

@interface IWSSender : NSObject

@property (strong) MRYIPCCenter* center;

- (id)init;
- (void)launchMobileSMS;
- (void)sendIPCText:(NSString *)body withSubject:(NSString *)subject toAddress:(NSString *)address withAttachments:(NSArray *)paths;
- (void)markConvoAsRead:(NSString *)chat_id;
- (void)sendTapback:(NSNumber *)tapback forGuid:(NSString *)guid inChat:(NSString *)chat;
- (void)sendTyping:(BOOL)isTyping forChat:(NSString *)chat;
- (void)removeObject:(NSString *)chat text:(NSString *)text;
//- (NSArray *)getPinnedChats;

@end

/*
@interface IMPinnedConversationsController
+ (id)sharedInstance;
- (NSOrderedSet *)pinnedConversationIdentifierSet;
@end
*/

@interface IMDaemonController
+ (id)sharedController;
- (BOOL)connectToDaemon;
@end

@interface CKConversationList
+ (id)sharedConversationList;
- (id)conversationForExistingChatWithGroupID:(NSString *)arg1;
@end

@interface CKConversation
- (void)setLocalUserIsTyping:(_Bool)arg1;
@end

@interface IMChat
- (void)markAllMessagesAsRead;
@end

@interface IMChatRegistry
+ (id)sharedInstance;
+ (IMChat *)existingChatWithChatIdentifier:(NSString *)chat_id;
@end

#endif /* Obj_h */
