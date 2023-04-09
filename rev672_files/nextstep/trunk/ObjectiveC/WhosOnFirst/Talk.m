#import <appkit/Pasteboard.h>
#import <appkit/Speaker.h>
#import <appkit/Listener.h>
#import "Talk.h"

/*===========================================================================

	File: Talk.m

	Purpose:  This file contains the code which implements the UNIX talk
		facility.  When a user requests "talk", terminal is 
		launched and the resulting csh is passed the talk command.

===========================================================================*/

@implementation Talk:Object

- init
{
	return self;
}

- copyString:(char *)s
{
	id p = [Pasteboard new];
	[p declareTypes:&NXAsciiPboard num:1 owner:self];
	[p writeType:NXAsciiPboard data:s length:strlen(s)];
	return self;
}

- launchTerminal:(char *)program
{
	id p = [NXApp appSpeaker];
	port_t t = NXPortFromName("Terminal",NULL);
	int ok;
	if (t==PORT_NULL) return self;
	[p setSendPort:t];
	[self copyString:program];
	(void)[p msgPaste:&ok];
	return self;
}

- talk:(char *) name tty:(char *) tty host:(char *) host
{
char command[256];

	sprintf(command,"talk %s %s\n", name, tty);
	[self launchTerminal:command];
	return self;
}

@end
