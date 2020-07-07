@interface MRYIPCCenter : NSObject
@property (nonatomic, readonly) NSString* centerName;
@property (nonatomic, readonly) NSArray<NSString*>* selectors;
+(instancetype)centerNamed:(NSString*)name;
-(void)addTarget:(id)target action:(SEL)action;
-(void)addTarget:(id(^)(id))target forSelector:(SEL)selector;
-(void)removeMethodForSelector:(SEL)selector;
//asynchronously call a void method
-(void)callExternalVoidMethod:(SEL)method withArguments:(id)args;
//synchronously call a method and recieve the return value
-(id)callExternalMethod:(SEL)method withArguments:(id)args;
//asynchronously call a method and receive the return value in the completion handler
-(void)callExternalMethod:(SEL)method withArguments:(id)args completion:(void(^)(id))completionHandler;

//deprecated
-(void)registerMethod:(SEL)selector withTarget:(id)target;
@end
