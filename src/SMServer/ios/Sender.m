#import <Foundation/Foundation.h>
#import "MRYIPCCenter.h"
#import "../shared/PrivateHeaders.h"
#import "Sender.h"
#import "SMServerIPC.h"

#define c(a) NSClassFromString(@#a)

@implementation IPCTextWatcher {
	/// This is a MCRYIPC center that libsmserver contacts whenever a new text is received.
	MRYIPCCenter* _center;
}

+ (instancetype)sharedInstance {
	static dispatch_once_t onceToken = 0;
	__strong static IPCTextWatcher* sharedInstance = nil;
	//MRYIPCCenter* center = [MRYIPCCenter centerNamed:@"com.ianwelker.smserverHandleText"];
	dispatch_once(&onceToken, ^{
		sharedInstance = [[self alloc] init];
	});
	return sharedInstance;
}

- (instancetype)init {
	if ((self = [super init])) {
		_center = [MRYIPCCenter centerNamed:@"com.ianwelker.smserverHandleText"];

		// have to try catch this 'cause libmryipc throws an exception when the port is already in use,
		// which occurs when we already have SMServer running in the background.
		@try {
			[_center addTarget:self action:@selector(handleReceivedTextWithCallback:)];
			[_center addTarget:self action:@selector(handlePartyTypingWithCallback:)];
			[_center addTarget:self action:@selector(handleSentTapbackWithCallback:)];
		}
		@catch (id exc) {
			NSString* log = [NSString stringWithFormat:@"\e[93;1mWARNING:\e[0m Failed to add selector for MRYIPCCenter: %@", exc];
			if ([[NSProcessInfo processInfo] arguments].count > 0)
				printf("%s\n", [log UTF8String]);
			else
				NSLog(@"SMServer_app: %@", log);
			return nil;
		}
	}
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
	if (self = [super init]) {
		self.center = [MRYIPCCenter centerNamed:@"com.ianwelker.smserver"];
		/// TODO: Find a way to add an NSNotificationCenter observer for the name "__kIMChatRegistryMessageSentNotification"
	}
	return self;
}

- (BOOL)sendIPCText:(NSString *)body withSubject:(NSString *)subject toAddress:(NSString *)address withAttachments:(NSArray *)paths {
	NSDictionary* args = @{@"body": body, @"subject": subject, @"address": address, @"attachment": paths};
	return [self.center callExternalMethod:@selector(sendText:) withArguments:args];
}

- (BOOL)markConvoAsRead:(NSString *)chat_id {
	NSArray* chats = [chat_id componentsSeparatedByString:@","]; /// To allow marking multiple convos as read
	for (NSString* chat in chats) {
		if (![[self.center callExternalMethod:@selector(setAllAsRead:) withArguments:chat] boolValue])
			return NO;
	}
	return YES;
}

- (BOOL)sendTapback:(NSNumber *)tapback forGuid:(NSString *)guid inChat:(NSString *)chat {
	NSDictionary* args = @{@"tapback": tapback, @"guid": guid, @"chat": chat};
	return [self.center callExternalMethod:@selector(sendTapback:) withArguments:args];
}

- (void)sendTyping:(BOOL)isTyping forChat:(NSString *)chat {
	NSBundle* imcore = [[NSBundle alloc] initWithPath:@"/System/Library/PrivateFrameworks/IMCore.framework"];
	[imcore load];

	//CKConversationList* sharedList = [c(CKConversationList) sharedConversationList];
	IMChatRegistry* registry = [c(IMChatRegistry) sharedInstance];
	//CKConversation* convo = [sharedList conversationForExistingChatWithGroupID:chat];
	IMChat* imchat = [registry existingChatWithChatIdentifier:chat];

	//[convo setLocalUserIsTyping:isTyping];
	[imchat setLocalUserIsTyping:isTyping];
}

- (BOOL)removeObject:(NSString *)chat text:(NSString *)text {
	NSMutableDictionary* args = [NSMutableDictionary dictionaryWithObject:chat forKey:@"chat"];
	if (text != nil)
		args[@"text"] = text;

	return [self.center callExternalMethod:@selector(delete:) withArguments:[NSDictionary dictionaryWithDictionary:args]];
}

/// This is not being used, but I am leaving it here for future versions in case I figure out how to make it work well.
/// The issue right now is that this code works when I sign it with the com.apple.messages.pinned
/// (or something like that) entitlement, but I can't have Xcode automatically sign it with that, so I'd have to
/// manually codesign each time that I want to debug. That would be a massive hassle so I'm not going to do it until
/// I find an easier solution

/// also it doesn't work correctly. Look to libSMServer for exactly how to do this correctly

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

