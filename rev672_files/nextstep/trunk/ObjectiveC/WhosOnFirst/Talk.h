#import <objc/Object.h>
#import <appkit/Application.h>
#import <string.h>

@interface Talk:Object
{
}

- init;
- talk:(char *) name tty:(char *) tty host:(char *) host;

@end
