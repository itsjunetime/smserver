#ifndef IPCTextWatcher_h
#define IPCTextWatcher_h

@interface IPCTextWatcher : NSObject

@property (copy) void(^setTexts)(NSString *);
@property (copy) void(^setTyping)(NSDictionary *);
@property (copy) void(^sentTapback)(int, NSString *);
+ (instancetype)sharedInstance;
- (unsigned)swizzled_capabilities:(id)listener_id;
- (void)setUpHooks;
@end

#endif /* IPCTextWatcher_h */
