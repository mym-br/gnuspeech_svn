
/* IconView.m */

#import <appkit/graphics.h>
#import <dpsclient/psops.h>
#import <dpsclient/wraps.h>
#import <libc.h>
#import <strings.h>
#import "IconView.h"
#import "ProcessManager.h"

extern id infoManager;
extern id processManager;

/*===========================================================================

	File: IconView.m

	Purpose:  Each icon is the instantiation of a window object. The
		docView of that window in an instantiation of this object.

		When an instance of this object gets a double click, it 
		queries the InfoMgr object for an action.  It then dispatches
		that action either to ProcessManager or myTalk.

===========================================================================*/

@implementation IconView

-init
{
	[self setFlipped: YES];		/* flip so that TEXT comes out OK */
	myTalk = [[Talk alloc] init];
	[[self window] addToEventMask:NX_MOUSEDOWNMASK];
	return(self);
}

-free
{
	[myTalk free];		/* Source of an earlier memory leak. Fixed now! */
	[super free];
	return nil;
}

- drawSelf:(const NXRect *)rects :(int)rectCount
{
NXRect   drawRect;
NXPoint  origin;

	/* initialize a drawing rectangle */
	drawRect.origin.x = drawRect.origin.y = 0.0;
	drawRect.size.width = drawRect.size.height = 64.0;	/* Icon Size 64x64 */
	origin.x = origin.y = 8.0;

	/* draw our bezel */
	NXDrawButton(&drawRect, 0);
	NXInsetRect(&drawRect, 1.0, 1.0);
	NXDrawButton(&drawRect, 0);
	NXInsetRect(&drawRect, -1.0, -1.0);

	PSsetgray(1.0);		/* Display user name and tty in white */
	PSmoveto(9.0,17.0);
	PSshow(username);
	PSmoveto(9.0,32.0);
	PSshow(ttyname);
	PSmoveto(9.0,47.0);
	PSshow(hostname);
	PSstroke();

	PSsetgray(0.0);		/* Display user name and tty in black */
	PSmoveto(9.0,18.0);
	PSshow(username);
	PSmoveto(8.0,33.0);
	PSshow(ttyname);
	PSmoveto(8.0,48.0);
	PSshow(hostname);
	PSstroke();

	return self;
}    

#define MOVEMASK (NX_MOUSEUPMASK|NX_MOUSEDRAGGEDMASK)
- mouseDown:(NXEvent *)theEvent
{
	if (theEvent->data.mouse.click == 2)
	{
		switch([infoManager doubleClickEvent])
		{
			case INFO_TALK:
				if ([infoManager confirmDoubleClick:"Initiate talk connection?"])
					[myTalk talk:username tty:ttyname host:hostname];
				break;

			case INFO_TTY_PROCESS:
				if ([infoManager confirmDoubleClick:"TTY process listing?"])
					[processManager readTTYProcesses:ttyname];
				break;

			case INFO_USER_PROCESS:
				if ([infoManager confirmDoubleClick:"User process listing?"])
					[processManager readUserProcesses:username];
				break;

			case INFO_LOGOUT:
				if ([infoManager confirmDoubleClick:"Logout?"])
					[processManager logoutTTY:ttyname];
				break;
		}

	}
	return self;
}

/*===========================================================================

	The following methods set various instance variables for this 
	object.

===========================================================================*/

- iconSetTty: (const char *) tty
{
	strcpy(ttyname, tty);	/* Set tty name */
	return(self);
}

- iconSetName: (const char *) name
{
	strcpy(username, name);	/* Set user name */
	username[8] = '\000';
	return(self);
}

- iconSetHostName: (const char *) name
{
	strcpy(hostname, name);	/* Set user name */
	return(self);
}

@end



