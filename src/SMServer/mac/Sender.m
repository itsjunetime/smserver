#import <Foundation/Foundation.h>
#import "MRYIPCCenter.h"
#import "Sender.h"

#define c(a) NSClassFromString(@#a)

@implementation IPCTextWatcher {
}

+ (instancetype)sharedInstance {
	static dispatch_once_t onceToken = 0;
	__strong static IPCTextWatcher* sharedInstance = nil;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[self alloc] init];
	});
	return sharedInstance;
}

- (instancetype)init {
	self = [super init];
	return self;
}

- (void)handleReceivedTextWithCallback:(NSString *)guid {
	/// This is the function that is called when a new text is received, or you send a text through SMServer.
	/// _setTexts is a block that is set somewhere around line 38 in `ServerDelegate.swift`, in `loadFuncs()`.
	_setTexts(guid);
}

- (void)handlePartyTypingWithCallback:(NSDictionary *)vals {
	/// This is called when someone else starts typing
	/// `_setTyping` is a block that is set somewhere around line 42 in `ServerDelegate.swift`, in `loadFuncs()`.
	_setTyping(vals);
}

- (void)handleSentTapbackWithCallback:(NSDictionary *)vals {
	/// This is called when you send a reaction through SMServer
	/// _sentTapback is a block that is set somewhere around line 46 in `ServerDelegate.swift`, in loadFuncs().
	_sentTapback([[vals objectForKey:@"tapback"] intValue], [vals objectForKey:@"guid"]);
}

@end

@implementation IWSSender

- (id)init {
	self = [super init];
	return self;
}

- (void)launchMobileSMS {
	//[self.center callExternalVoidMethod:@selector(launchSMS) withArguments:nil];
}

- (BOOL)sendIPCText:(NSString *)body withSubject:(NSString *)subject toAddress:(NSString *)address withAttachments:(NSArray *)paths {
	NSDictionary* args = @{@"body": body, @"subject": subject, @"address": address, @"attachment": paths};
	//return [self.center callExternalMethod:@selector(sendText:) withArguments:args];
	return false;
}

- (BOOL)markConvoAsRead:(NSString *)chat_id {
	NSArray* chats = [chat_id componentsSeparatedByString:@","]; /// To allow marking multiple convos as read
	/*for (NSString* chat in chats) {
		if (![[self.center callExternalMethod:@selector(setAllAsRead:) withArguments:chat] boolValue])
			return NO;
	}*/
	return NO;
}

- (BOOL)sendTapback:(NSNumber *)tapback forGuid:(NSString *)guid inChat:(NSString *)chat {
	NSDictionary* args = @{@"tapback": tapback, @"guid": guid, @"chat": chat};
	//return [self.center callExternalMethod:@selector(sendTapback:) withArguments:args];
	return NO;
}

- (void)sendTyping:(BOOL)isTyping forChat:(NSString *)chat {
	NSBundle* imcore = [[NSBundle alloc] initWithPath:@"/System/Library/PrivateFrameworks/IMCore.framework"];
	[imcore load];

	//CKConversationList* sharedList = [c(CKConversationList) sharedConversationList];
	IMChatRegistry* registry = [c(IMChatRegistry) sharedInstance];
	//CKConversation* convo = [sharedList conversationForExistingChatWithGroupID:chat];
	IMChat* convo = [registry existingChatWithChatIdentifier:chat];

	[convo setLocalUserIsTyping:isTyping];
}

- (BOOL)removeObject:(NSString *)chat text:(NSString *)text {
	NSDictionary* args = @{@"chat": chat, @"text": text};
	//return [self.center callExternalMethod:@selector(delete:) withArguments:args];
	return NO;
}

/// This is not being used, but I am leaving it here for future versions in case I figure out how to make it work well.
/// The issue right now is that this code works when I sign it with the com.apple.messages.pinned
/// (or something like that) entitlement, but I can't have Xcode automatically sign it with that, so I'd have to
/// manually codesign each time that I want to debug. That would be a massive hassle so I'm not going to do it until
/// I find an easier solution

/*- (NSArray *)getPinnedChats {
 NSBundle* imcore = [[NSBundle alloc] initWithPath:@"/System/Library/PrivateFrameworks/IMCore.framework"];
 [imcore load];

 IMDaemonController* controller = [c(IMDaemonController) sharedController];
 __block NSArray* pins = [NSArray array];

 if ([controller connectToDaemon] && [[NSProcessInfo processInfo] operatingSystemVersion].majorVersion >= 14) {
	IMPinnedConversationsController* pinnedController = [c(IMPinnedConversationsController) sharedInstance];
	NSOrderedSet* set = [pinnedController pinnedConversationIdentifierSet];

	pins = [set array];
 }

 return pins;
}*/

@end

