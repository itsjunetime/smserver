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

#if !TARGET_OS_IPHONE

@interface IMDaemonSingleton
+ (id)sharedDaemon;
@end

@interface IMDaemon
- (BOOL)daemonInterface:(id)arg1 shouldGrantAccessForPID:(SEL)arg2 auditToken:(id)arg3 portName:(int)arg4 listenerConnection:(id)arg5 setupInfo:(id)arg6 setupResponse:(id*)arg7;
- (BOOL)daemonInterface:(id)arg1 shouldGrantPlugInAccessForPID:(SEL)arg2 auditToken:(id)arg3 portName:(int)arg4 listenerConnection:(id)arg5 setupInfo:(id)arg6 setupResponse:(id*)arg7;
@end

#endif

#endif /* PrivateHeaders_h */
