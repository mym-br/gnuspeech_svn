#import "InfoMgr.h"
#import "DefaultMgr.h"
#import "myMainObject.h"
#import <stdlib.h>
#import <libc.h>
#import <ctype.h>
#import <appkit/Application.h>
#import <appkit/Window.h>
#import <appkit/View.h>
#import <appkit/Control.h>
#import <appkit/ActionCell.h>
#import <appkit/TextField.h>
#import <appkit/Button.h>
#import <appkit/OpenPanel.h>
#import <appkit/Matrix.h>
#import <sys/param.h>

id infoManager;
/*===========================================================================

	File: InfoMgr.m

	Purpose: This file is not just an infoManager.  It is an 
		Info/Preferences manager.  However, due to the constant 
		revisions (and no real code re-organizations) this file is 
		now the multi-purpose beast that it is.  Re-organization
		may take place at some later date.

===========================================================================*/

@implementation InfoMgr

- init
{
	[super init];

	generalView = infoView;		/* See nib files for this one */
	return self;
}

/*===========================================================================

	Method: initDefaults

	Purpose: To get the defaults from the default manager into instance
		 variables and interface objects.

	Called: From appDidInit:sender

===========================================================================*/

- initDefaults
{
	[speakMessages setStringValue:[defaultManager loginMessage] at:0];
	[speakMessages setStringValue:[defaultManager logoutMessage] at:1];

	[whenToSpeak selectCellAt: [defaultManager whenToSpeak] :0];
	[doubleClickAction selectCellAt: [defaultManager doubleClickAction] :0];

	[confirmDoubleClick setState:[defaultManager doubleClickConfirm]];

	[[speakLog cellAt:0 :0] setState:[defaultManager speakLogin]];
	[[speakLog cellAt:0 :1] setState:[defaultManager speakLogout]];

	return self;
}

/*===========================================================================

	Method: initSpeech: (const char *) dictPath

	Purpose: To allocate and initialize the speech object.  

	Algorithm: 
		o Allocate and initialize speech object.
		o Set the dictionary ordering to our preference
		o set the Application dictionary path.

	NOTE:  The Application Dictionary (WhosOnFirst.preditor) is located
		in WhosOnFirst.app/.  However, because the speech object is
		communicating with a Speech Server, the server has no idea
		where WhosOnFirst.app is located in the directory hierarchy.
		Therefore, the full path to the dictionary file must be
		provided to this method.  Please see myMainObject.m, 
		-appDidInit:sender for more code.  See TextToSpeech Kit
		documentation for a description of the setAppDictPath: 
		method.

		Compilation of this method is conditional.  See 
		Makefile.preamble to set up conditional compilation flags.

===========================================================================*/
#ifdef SPEECH

- initSpeech:(const char *) dictPath
{
short dictOrder[5] = { TTS_NUMBER_PARSER, TTS_USER_DICTIONARY, TTS_APPLICATION_DICTIONARY,
			TTS_MAIN_DICTIONARY, TTS_LETTER_TO_SOUND};

	if (!mySpeech) mySpeech = [[TextToSpeech alloc] init];
	if (mySpeech == nil)
	{
		sleep(5);
		mySpeech = [[TextToSpeech alloc] init];		/* Avoid high load problems */
	}
	if (mySpeech == nil)
	{
		if ([[whenToSpeak selectedCell] tag]!=SPEECHOFF)
		{
			if (NXRunAlertPanel("TextToSpeech","Could not launch TextToSpeech Server", "Disable Speech",
							"Ignore", NULL)==1) [whenToSpeak selectCellAt: 0 :0];
		}
	}
	else
	{
		[mySpeech setDictionaryOrder: dictOrder];
		[mySpeech setAppDictPath: dictPath];
	}
	return self;
}

#endif

/*===========================================================================

	Method: cleanUp

	Purpose: To update the defaults manager in preparation for 
		application termination.

===========================================================================*/
- cleanUp
{
int temp;

	temp = [[whenToSpeak selectedCell] tag];
	[defaultManager setWhenToSpeak:temp];

	temp = [[doubleClickAction selectedCell] tag];
	[defaultManager setDoubleClickAction:temp];

	[defaultManager setLoginMessage: [speakMessages stringValueAt:0]];
	[defaultManager setLogoutMessage: [speakMessages stringValueAt:1]];

	[defaultManager setSpeakLogin: (BOOL)[[speakLog cellAt:0 :0] state]];
	[defaultManager setSpeakLogout: (BOOL)[[speakLog cellAt:0 :1] state]];
	
	[defaultManager setDoubleClickConfirm: (BOOL)[confirmDoubleClick state]];


	return self;
}

/*===========================================================================

	Method: switchViews:sender

	Purpose: To switch the view hierarchy based on the selection of the
		pop-up menu on the info panel

===========================================================================*/

- switchViews:sender
{
	[window disableFlushWindow];
	[generalView removeFromSuperview];
	switch ([[sender selectedCell] tag])
	{
		case 0:
			[[window contentView] addSubview:infoView];
			generalView = infoView;
			break;
		case 1:
			[[window contentView] addSubview:speechView];
			generalView = speechView;
			break;
		case 2:
			[[window contentView] addSubview:speechControlView];
			generalView = speechControlView;
			break;
		case 3:
			[[scrollView docView] display];
			[[window contentView] addSubview:iconInfoView];
			generalView = iconInfoView;
			break;
		case 4:
			[[window contentView] addSubview:TextToSpeechView];
			generalView = TextToSpeechView;
			break;
	}
	[[window contentView] display];
	[window reenableFlushWindow];
	[window flushWindow];

	return self;
}

/*===========================================================================

	Method: doubleClickEvent

	Purpose: An IconView will receive any double click events.  This
		method is here to provide IconView with information about 
		what is to be done in the event of a double click.

===========================================================================*/

-(int) doubleClickEvent
{
	return([[doubleClickAction selectedCell] tag]);
}

/*===========================================================================

	Method: confirmDoubleClick

	Purpose: If the user has requested confirmation of Double Click
		events, display a panel with message supplied in the variable
		"message" return the value returned by the panel.

		If the user has not requested confirmation of double clicks,
		simply return true.

===========================================================================*/

-(int) confirmDoubleClick:(const char *) message
{

	if (![confirmDoubleClick state])
		return(1);
	else
		return(NXRunAlertPanel("Double Click Confirmation", message, "Ok", "Cancel", NULL));
}

#ifndef SPEECH
- enableSpeech:sender
{
	return self;
}
#endif

/*===========================================================================

	Compilation of the following methods is conditional.  See 
	Makefile.preamble to set up conditional compilation flags.

===========================================================================*/

#ifdef SPEECH

- enableSpeech:sender
{
char dictPath[256];
const char *appPath;

	if (mySpeech) return self;
	if ([[whenToSpeak selectedCell] tag] != SPEECHOFF)
	{
		appPath = [mainObject appDirectory];
		strcpy(dictPath, appPath);
		strcat(dictPath, "/WhosOnFirst.preditor");

		/* Initialize the speech. Include the application dictionary.*/
		[self initSpeech:dictPath];
	}
	return self;
}


/*===========================================================================

	Method:speakLoginMessage

	Purpose: Given the user's preference settings, speak the appropriate
		login message.

===========================================================================*/

- speakLoginMessage:(const char *) user tty:(const char *) tty host:(const char *) host
{
char tempHostName[MAXHOSTNAMELEN];

	if ([[speakLog cellAt:0 :0] state])			/* Speak login messages? */
		switch([[whenToSpeak selectedCell] tag])	/* Get message from info panel */
		{
			case SPEECHOFF: 			/* No Speech */
					break;

			case ANYUSER:				/* Speak for any user */
					[self speakFormatString: [speakMessages stringValueAt:0]
						name: user tty:tty host:host];

					break;

			case OTHERUSERS:			/* Speak for other users */
					if (strcmp(getlogin(), user))
						[self speakFormatString: [speakMessages stringValueAt:0]
							name: user tty:tty host:host];
					break;

			case REMOTEUSERS: 			/* Speak for remote users */
					gethostname(tempHostName, MAXHOSTNAMELEN);
					if (strcmp(host, tempHostName))
						[self speakFormatString: [speakMessages stringValueAt:0]
							name: user tty:tty host:host];
					break;

		}
	return self;
}

/*===========================================================================

	Method:speakLogoutMessage

	Purpose: Given the user's preference settings, speak the appropriate
		logout message.

===========================================================================*/

- speakLogoutMessage:(const char *) user tty:(const char *) tty host:(const char *) host
{
char tempHostName[MAXHOSTNAMELEN];

	if ([[speakLog cellAt:0 :1] state])			/* Speak logout messages? */
		switch([[whenToSpeak selectedCell] tag])
		{
			case SPEECHOFF: 			/* No Speech */
					break;

			case ANYUSER:				/* Speak for any user */
					[self speakFormatString: [speakMessages stringValueAt:1]
						name: user tty:tty host:host];

					break;

			case OTHERUSERS:			/* Speak for other users */
					if (strcmp(getlogin(), user))
						[self speakFormatString: [speakMessages stringValueAt:1]
							name: user tty:tty host:host];
					break;

			case REMOTEUSERS:			/* Speak for remote users */
					gethostname(tempHostName, MAXHOSTNAMELEN);
					if (strcmp(host, tempHostName))
						[self speakFormatString: [speakMessages stringValueAt:1]
							name: user tty:tty host:host];
					break;

		}
	return self;
}
/*===========================================================================

	Method: SpeakFormatString: format
			name: user
			tty: tty
			host: host

	Purpose: Given that a message is to be spoken, get the message format
		string from the info panel and construct a speak message
		which conforms to the format string.

===========================================================================*/

- speakFormatString:(const char *) format name:(const char *) user tty:(const char *) tty host:(const char *) host
{
int i, j = 0, k = 0;
char finalString[1024];

	bzero(finalString, 1024);

	i = strlen(format);
	while(j<i)
	{
		switch(format[j])
		{
			case '%':switch(format[j+1])
				 {
					/* Insert login name */
					case 'u': strncat(finalString, user, 8);
						  j+=2;
						  break;

					/* Insert host name */
					case 'h': strcat(finalString, host);
						  j+=2;
						  break;

					/* Insert tty name */
					case 't': strcat(finalString, tty);
						  j+=2;
						  break;

					/* A single % sign. */
					default: finalString[k] = '%';
						 break;
				 }
				 k = strlen(finalString);
				 break;

			default: finalString[k++] = format[j++];
				 break;
		}
	}


	if (!mySpeech) [self enableSpeech:self];
	/* Here we are!  Actually tell the speech object to Speak the message :-) */
	[mySpeech speakText:finalString];

	return self;
}

#endif

- notifyLaunch: (const char *) appName
{
#ifdef SPEECH
char *temp;
char *temp1;
char buffer[256];
char buffer2[256];
int i,j;

	temp = rindex(appName,'/');
	if (temp)
	{
		temp++;
		temp1 = (char *) malloc (strlen (temp)+1);
		strcpy(temp1, temp);
		temp = rindex(temp1, '.');
		if (temp)
			*temp = '\000';

		bzero(buffer2, 256);
		i = 0;
		j = 0;
		while(temp1[i]!='\000')
		{
			if (isupper(temp1[i]))
			{
				buffer2[j++] = ' ';
				buffer2[j++] = temp1[i++];
			}
			else
			{
				buffer2[j++] = temp1[i++];
			}
		}

		sprintf(buffer, "%s launched", buffer2);
//		printf("Buffer = %s\n", buffer2);
		[mySpeech speakText:buffer];
		free(temp1);
	}

#endif
	return self;
}

- notifyTerminate: (const char *) appName
{
#ifdef SPEECH
char *temp;
char *temp1;
char buffer[256];
char buffer2[256];
int i,j;

	temp = rindex(appName,'/');
	if (temp)
	{
		temp++;
		temp1 = (char *) malloc (strlen (temp)+1);
		strcpy(temp1, temp);
		temp = rindex(temp1, '.');
		if (temp)
			*temp = '\000';

		bzero(buffer2, 256);
		i = 0;
		j = 0;
		while(temp1[i]!='\000')
		{
			if (isupper(temp1[i]))
			{
				buffer2[j++] = ' ';
				buffer2[j++] = temp1[i++];
			}
			else
			{
				buffer2[j++] = temp1[i++];
			}
		}

		sprintf(buffer, "%s terminated", buffer2);
//		printf("Buffer = %s\n", buffer2);
		[mySpeech speakText:buffer];
		free(temp1);
	}


#endif

	return self;
}

@end
