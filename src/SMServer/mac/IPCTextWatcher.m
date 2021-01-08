#import <objc/runtime.h>
#import <Foundation/Foundation.h>

#include "IPCTextWatcher.h"
#include "../shared/PrivateHeaders.h"

@implementation IPCTextWatcher

+ (instancetype) sharedInstance {
	static dispatch_once_t onceToken = 0;
	__strong static IPCTextWatcher* sharedInstance = nil;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[self alloc] init];
	});
	return sharedInstance;
}

/*unsigned hooked_capabilities(id self, SEL _cmd) {
	return 17159;
}*/

- (unsigned int)swizzled_capabilities:(id)listener_id {
	return 17159;
}

- (void)setUpHooks {

	/// Hooking IMDaemon _capabilities
	//IMP swizzle_imp = (IMP)hooked_capabilities;
	Method original = class_getInstanceMethod([NSClassFromString(@"IMDaemonController") class], @selector(capabilitiesForListenerID:));
	Method swizzled = class_getInstanceMethod([self class], @selector(swizzled_capabilities:));

	//IMP original_imp = method_setImplementation(original_method, swizzle_imp);
	method_exchangeImplementations(original, swizzled);

	IMDaemonController* controller = [NSClassFromString(@"IMDaemonController") sharedController];
	unsigned capabilities = [controller capabilitiesForListenerID:@"SMServer"];
	NSLog(@"capabilities: %u", capabilities);
	unsigned new_capabilities = [controller hooked_capabilities:nil];
	NSLog(@"new: %u", new_capabilities);
}

@end
