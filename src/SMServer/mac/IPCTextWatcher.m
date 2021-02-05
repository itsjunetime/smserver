#import <objc/runtime.h>
#import <Foundation/Foundation.h>

#include "IPCTextWatcher.h"
#include "../shared/PrivateHeaders.h"

#define Daemon NSClassFromString(@"IMDaemonController")

@implementation IPCTextWatcher

+ (instancetype) sharedInstance {
	static dispatch_once_t onceToken = 0;
	__strong static IPCTextWatcher* sharedInstance = nil;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[self alloc] init];
	});
	return sharedInstance;
}

- (unsigned int)swizzled_capabilities:(id)listener_id {
	return 17159;
}

- (BOOL)swizzledDaemonInterface:(id)arg1 shouldGrantAccessForPID:(SEL)arg2 auditToken:(id)arg3 portName:(int)arg4 listenerConnection:(id)arg5 setupInfo:(id)arg6 setupResponse:(id*)arg7 {
	return YES;
}

- (BOOL)swizzledDaemonInterface:(id)arg1 shouldGrantPlugInAccessForPID:(SEL)arg2 auditToken:(id)arg3 portName:(int)arg4 listenerConnection:(id)arg5 setupInfo:(id)arg6 setupResponse:(id*)arg7 {
	return YES;
}

- (void)setUpHooks {
	NSBundle *framework = [[NSBundle alloc] initWithPath:@"/System/Library/PrivateFrameworks/IMCore.framework"];
	[framework load];
	
	/// Hooking IMDaemon _capabilities
	Method original_cap = class_getInstanceMethod([Daemon class], @selector(capabilitiesForListenerID:));
	Method swizzled_cap = class_getInstanceMethod([self class], @selector(swizzled_capabilities:));
	
	method_exchangeImplementations(original_cap, swizzled_cap);
	
	Method original_grant = class_getInstanceMethod([NSClassFromString(@"IMDaemon") class], @selector(daemonInterface:shouldGrantAccessForPID:auditToken:portName:listenerConnection:setupInfo:setupResponse:));
	Method swizzled_grant = class_getInstanceMethod([self class], @selector(swizzledDaemonInterface:shouldGrantAccessForPID:auditToken:portName:listenerConnection:setupInfo:setupResponse:));
	
	method_exchangeImplementations(original_grant, swizzled_grant);

	IMDaemonController* controller = [Daemon sharedController];
	unsigned capabilities = [controller capabilitiesForListenerID:@"SMServer"];
	NSLog(@"capabilities: %u", capabilities);
	
	if ([controller connectToDaemon]) {
		IMChatRegistry* reg = [NSClassFromString(@"IMChatRegistry") sharedInstance];
	} else {
		NSLog(@"no connect");
	}
}

@end
