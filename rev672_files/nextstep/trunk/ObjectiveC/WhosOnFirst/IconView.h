
/* IconView.h */

#import <appkit/View.h>
#import "Talk.h"
#import "InfoMgr.h"

extern id InfoManager;		/* Get info/preferences */

@interface IconView:View
{
	char username[10];	/* User name to display in Icon */
	char ttyname[10];	/* TTY name to display */
	char hostname[64];	/* Hostname to display */
	Talk *myTalk;
}

- init;
- free;
- drawSelf:(const NXRect *)rects :(int)rectCount;
- mouseDown:(NXEvent *)theEvent;
- iconSetTty: (const char *) tty;	/* Set instance variable ttyname */
- iconSetName: (const char *) name;	/* Set instance variable username */
- iconSetHostName: (const char *) name;	/* Set instance variable hostname */

@end
