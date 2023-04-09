#import <objc/objc.h>
#import <appkit/appkit.h>


@interface ProcessManager:Object
{
	id	myTextObject;
	id	myWindow;
}

- readTTYProcesses: (char *) tty;
- readUserProcesses: (char *) name;
- logoutTTY:(char *) ttyname;

@end