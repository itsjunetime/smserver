#ifndef IPCTextWatcher_h
#define IPCTextWatcher_h

@interface IPCTextWatcher : NSObject

@property (copy) void(^setTexts)(NSString *);
@property (copy) void(^setTyping)(NSDictionary *);
@property (copy) void(^sentTapback)(int, NSString *);
+ (instancetype)sharedInstance;
- (unsigned)swizzled_capabilities:(id)listener_id;
- (BOOL)swizzledDaemonInterface:(id)arg1 shouldGrantAccessForPID:(SEL)arg2 auditToken:(id)arg3 portName:(int)arg4 listenerConnection:(id)arg5 setupInfo:(id)arg6 setupResponse:(id*)arg7;
- (BOOL)swizzledDaemonInterface:(id)arg1 shouldGrantPlugInAccessForPID:(SEL)arg2 auditToken:(id)arg3 portName:(int)arg4 listenerConnection:(id)arg5 setupInfo:(id)arg6 setupResponse:(id*)arg7;
- (void)setUpHooks;
@end

#endif /* IPCTextWatcher_h */
