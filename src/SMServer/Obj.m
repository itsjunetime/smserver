#import <Foundation/Foundation.h>
#import "MRYIPCCenter.h"

#import "Obj.h"

@implementation IPCTextWatcher {
    /// This is a MCRYIPC center that libsmserver contacts whenever a new text is received.
    MRYIPCCenter* _center;
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
    if ((self = [super init])) {
        _center = [MRYIPCCenter centerNamed:@"com.ianwelker.smserverHandleText"];
        [_center addTarget:self action:@selector(handleReceivedTextWithCallback:)];
        [_center addTarget:self action:@selector(handleBatteryChanged)];
    }
    return self;
}

- (void)handleReceivedTextWithCallback:(NSString *)chat_id {
    /// This is the function that is called when a new text is received.
    /// _setTexts is a block that is set somewhere around line 677 in ContentView.swift, in loadFuncs(). 
    _setTexts(chat_id);
}

- (void)handleBatteryChanged {
    _setBattery();
}

@end

@implementation IWSSender

- (void)relaunchApp {
    
    NSLog(@"SMServer_app: Relaunching app in objc");
    
    MRYIPCCenter* center = [MRYIPCCenter centerNamed:@"com.ianwelker.smserverLaunch"];
    [center callExternalVoidMethod:@selector(relaunchSMServer) withArguments:nil];
    
}

- (void)launchMobileSMS {
    NSLog(@"SMServer_app: Entered obj-c func, launching MobileSMS");
    
    MRYIPCCenter* center = [MRYIPCCenter centerNamed:@"com.ianwelker.smserverLaunch"];
    [center callExternalVoidMethod:@selector(launchSMS) withArguments:nil];
}

- (uid_t)setUID {
    setuid(0);
    setgid(0);
    
    return getuid() + getgid();
}

- (void)sendIPCText:(NSString *)body toAddress:(NSString *)address withAttachments:(NSArray *)paths {
    
    MRYIPCCenter* center = [MRYIPCCenter centerNamed:@"com.ianwelker.smserver"];
    [center callExternalVoidMethod:@selector(sendText:) withArguments:@{@"body": body, @"address": address, @"attachment": paths}];
    
}

- (void)markConvoAsRead:(NSString *)chat_id {
    
    MRYIPCCenter* center = [MRYIPCCenter centerNamed:@"com.ianwelker.smserver"];
    [center callExternalVoidMethod:@selector(setAllAsRead:) withArguments:chat_id];
    
}

@end

