#include <stdio.h>
#ifdef V2
#import <mach.h>
#endif
#ifdef V3
#import <mach/mach.h>
#endif
#include "diphone_module.h"
#include "structs.h"

#import "RealTimeController.h"

static char file_id[] = "@(#)Structure Control. Author: Craig-Richard Schock. (C) Trillium, 1991, 1992, 1993.";

struct _speak_messages speak_messages[MAX_SPEAK_MESSAGES];
int in_speak_message, out_speak_message, message_queue_empty;

char globalSystemPath[256];

extern struct _calc_info calc_info;

RealTimeController *realTime;


init_all(systemPath)
const char *systemPath;
{
thread_t temp;
kern_return_t error;

	strcpy(globalSystemPath, systemPath);		/* Save for later.  Used w/ Serial number */
	init_server();
	init_databases(systemPath);	/* Needs path */
	init_parser_module();
	init_users();
	init_messages();
	init_tone_groups(systemPath);	/* Needs path */
	init_mainDict(systemPath);	/* Needs path */
	init_voices(systemPath);	/* Needs Path */
	init_vowel_transitions(systemPath); 	/* needs path */

}

init_messages()
{
int i;
	bzero(speak_messages, sizeof(struct _speak_messages)*MAX_SPEAK_MESSAGES);
	in_speak_message = out_speak_message = 0;
	message_queue_empty = TRUE;
	for (i = 0;i<MAX_SPEAK_MESSAGES;i++) speak_messages[i].ident = (-1);
}

init_databases(systemPath)
const char *systemPath;
{
#define monetName "/diphones.monet"
char tempPath[256];

	sprintf(tempPath,"%s%s", systemPath, monetName);
//	printf("Initing monetFile \"%s\"\n", tempPath);
	realTime = [[RealTimeController alloc] initWithFile: tempPath];

	if (realTime == nil)
	{
		printf("Cannot open monetFile \"%s\"\n", tempPath);
		return 0;
	}

	return 1;
}

init_events()
{

	return;
}

