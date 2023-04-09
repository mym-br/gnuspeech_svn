#import <stdio.h>
#import <sys/dir.h>
#import <TextToSpeech/TextToSpeech.h>
#import <objc/objc.h>

/*===========================================================================

	File: mailServer.h
	Author: Craig-Richard Taube-Schock

	Purpose: This file holds the mail functions for the mailServer 
		 program.  

	Date: February 22, 1993.
	Last Modified: February 25, 1993.

===========================================================================*/

@interface MailServer : Object

struct _messageInfo {
	int number;
	char *user;
	char **subjects;
};

- init;
- updateMail;
- parseMail;

@end
