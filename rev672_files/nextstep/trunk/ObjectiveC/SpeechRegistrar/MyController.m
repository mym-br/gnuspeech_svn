#import "MyController.h"
#import <TextToSpeech/TextToSpeech.h>
#import "TextToSpeechDemo.h"
#import "TextToSpeechPriority.h"
#import "serverDefaults.h"
#import <sys/types.h>
#import <sys/stat.h>
#import <math.h>
#include <stdio.h>
#include <string.h>
#import <streams/streams.h>
#import "andMap.h"


@implementation MyController

- appDidInit:sender
{
char buffer[256];
float version;

	if (getuid()!=0)
	{
		NXRunAlertPanel("Registration", "You must be root to register the TextToSpeech Kit", "Ok", NULL, NULL);
		[regButton setEnabled:NO];
	}

	mySpeech = [[TextToSpeech alloc] init];
	if (!mySpeech)
	{
		mySpeech = [[TextToSpeech alloc] init];
		if (!mySpeech)
		{
			NXRunAlertPanel("TextToSpeech Server", "Cannot launch TextToSpeech Server.", "Ok", NULL, NULL);
			exit(0);
		}
	}

	version = atof([mySpeech serverVersion]);
	if (version<=2.0)
	{
		sprintf(buffer,"Registered.  Version %.2f\n", version);
		[regStatusField setStringValue: buffer];
		[regButton setEnabled:NO];
	}
	else
	{
		switch([mySpeech demoMode])
		{
			case (-1): sprintf(buffer,"Incorrect Password");
				[regStatusField setStringValue: buffer];
				break;
			case 0: [regStatusField setStringValue: "Registered."];
				[regButton setEnabled:NO];
				break;
			default:[regStatusField setStringValue: "Unregistered Demonstration"];
				break;
		}

	}

	passwordTries = 0;

	return self;
}

- registerDemo:sender
{
int fd;
char buffer[128], path[256];
const char *systemPathPtr;

	[passwordField selectText:sender];

	NXSetDefaultsUser(TTS_NXDEFAULT_ROOT_USER);
	if ((systemPathPtr = NXReadDefault(TTS_NXDEFAULT_OWNER,TTS_NXDEFAULT_SYSTEM_PATH))==NULL)
	{
		NXRunAlertPanel("Registration", "Cannot find systemPath for the TextToSpeech Kit.", "Ok", NULL, NULL);
		NXSetDefaultsUser((const char *) NXUserName());
		NXLogError("TTS server:  Could not find systemPath for the TextToSpeech Kit in root's defaults database.");
		exit(-2);
	}

	sprintf(path, "%s/SerialNumber", systemPathPtr);


	fd = open(path, O_CREAT|O_WRONLY, S_IREAD);

	sprintf(buffer, "%s\n", [passwordField stringValue]);
	write(fd, buffer, strlen(buffer));

	fchmod(fd, S_IREAD);
	close (fd);

	[regStatusField setStringValue:"Registering... Please Wait"];
	NXPing();
	[mySpeech requestServerRestart];
	sleep(8);

	switch([mySpeech demoMode])
	{
		case (-1): sprintf(buffer,"Incorrect Password");
			[regStatusField setStringValue: buffer];
			break;
		case 0: [regStatusField setStringValue: "Registered."];
			[regButton setEnabled:NO];
			break;
		default:[regStatusField setStringValue: "Unregistered Demonstration"];
			break;
	}

	passwordTries++;

	if (passwordTries >= 3)
	{
		sleep(15);
		unlink(path);
		NXRunAlertPanel("Registration", "Incorrect Password.  Please contact Trillium Sound Research Inc.", "Ok", NULL, NULL);
		exit(-1);
	}
	return self;
}

@end
