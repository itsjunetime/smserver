#ifndef PrivateHeaders_h
#define PrivateHeaders_h

/*
@interface IMPinnedConversationsController
+ (id)sharedInstance;
- (NSOrderedSet *)pinnedConversationIdentifierSet;
@end
 */

@interface IMDaemonController
+ (id)sharedController;
- (BOOL)connectToDaemon;
- (unsigned)_capabilities;
- (unsigned)hooked_capabilities:(id)arg1;
- (unsigned int)capabilitiesForListenerID:(id)arg1;
@end

@interface IMChat
- (void)markAllMessagesAsRead;
- (void)setLocalUserIsTyping:(BOOL)arg1;
- (void)sendMessage:(id)arg1;
@end

@interface IMChatRegistry
+ (id)sharedInstance;
- (IMChat *)existingChatWithChatIdentifier:(NSString *)chat_id;
@end

@interface IMMessage
+ (id)instantMessageWithText:(NSAttributedString *)arg1 flags:(long long)arg2 threadIdentifier:(id)arg3;
+ (id)instantMessageWithText:(NSAttributedString *)arg1 flags:(long long)arg2;
- (id)guid;
@end

#endif /* PrivateHeaders_h */
