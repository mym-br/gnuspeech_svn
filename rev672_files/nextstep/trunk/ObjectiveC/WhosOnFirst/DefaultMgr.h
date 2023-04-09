
#import <objc/Object.h>;
#import <objc/objc.h>
#import <defaults/defaults.h>

@interface DefaultMgr:Object
{
}

+ initialize;
- updateDefaults;
- writeDefaults;
- (BOOL)speakLogin;
- setSpeakLogin:(BOOL) value;
- (BOOL)speakLogout;
- setSpeakLogout:(BOOL) value;
- (int) whenToSpeak;
- setWhenToSpeak:(int) value;
- (const char *) loginMessage;
- setLoginMessage:(const char *) message;
- (const char *)logoutMessage;
- setLogoutMessage:(const char *) message;
- (int)doubleClickAction;
- setDoubleClickAction:(int) value;
- (BOOL)doubleClickConfirm;
- setDoubleClickConfirm:(BOOL) value;


@end