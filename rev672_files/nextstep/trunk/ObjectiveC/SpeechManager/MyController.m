
#import "MyController.h"
#import <TextToSpeech/TextToSpeech.h>
#import "TextToSpeechPriority.h"
#import <appkit/Slider.h>
#import <appkit/TextField.h>
#import <appkit/Panel.h>
#import <appkit/Matrix.h>
#import <math.h>
#import <nikit/NILoginPanel.h>
#import <nikit/NIDomain.h>
#import <libc.h>

static inline char *dindex(char *buf, char *string)
{
int len = strlen(string);

        for (; *buf; buf++)
                if (strncmp(buf, string, len) == 0)
                        return (buf);
                return (NULL);
}

@implementation MyController

- appDidInit:sender
{
int tempPriority, tempQuantum, tempPolicy, tempPrefill;
float version;
id tempNiDomain, tempLoginPanel;
BOOL tempInactiveKill;

/*	tempNiDomain = [[NIDomain alloc] init];
	printf("%s\n", ni_error([tempNiDomain setConnection:(const char *) "."]));
	printf("Handle: %d\n", (int) [tempNiDomain getDomainHandle]);
	printf("Last error: %s\n", ni_error([tempNiDomain lastError]));
	tempLoginPanel = [NILoginPanel new];
	if ([tempLoginPanel runModal:self inDomain: [tempNiDomain getDomainHandle] 
		withUser:"root" withInstruction:"You must be root to run this program."
		allowChange:FALSE] )
	{
		printf("OK\n");
		printf("%d\n", (int)[tempLoginPanel isValidLogin:self]);
	}
	else
		printf("Not right!\n");

*/
	if (getuid()!=0)
	{
		NXRunAlertPanel ("Permission Denied",
			"You must be root to run this program.",
			"OK", NULL, NULL);
		exit(0);
	}

	mySpeech = [[TextToSpeech alloc] init];
	if (!mySpeech)
	{
		[connectPanel orderFront:self];
		sleep(5);
		mySpeech = [[TextToSpeech alloc] init];
		[connectPanel orderOut:self];
		if (!mySpeech)
		{
			NXRunAlertPanel ("Cannot connect",
				"Too many clients, or TTS_server cannot be started.",
				"OK", NULL, NULL);
  			exit(0);
		}

	}

	version = atof([mySpeech serverVersion]);

	if (version<(float)1.07)
	{
		NXRunAlertPanel ("Old Speech Server.",
			"Need TextToSpeech Server V1.07 or later.",
			"OK", NULL, NULL);
		exit(0);
	}


	tempPriority = [mySpeech getPriority];
	tempQuantum = [mySpeech getQuantum];
	tempPolicy = [mySpeech getPolicy];
	tempPrefill = [mySpeech getSilencePrefill];
	tempInactiveKill = [mySpeech inactiveKillQuery];

	[machPriorityField setIntValue:tempPriority];
	[machPrioritySlider setIntValue:tempPriority];

	[timeQuantumField setIntValue:tempQuantum];
	[timeQuantumSlider setIntValue:tempQuantum];

	[silencePrefillField setIntValue:tempPrefill];
	[silencePrefillSlider setIntValue:tempPrefill];

	[killSwitch setState:tempInactiveKill];

	switch(tempPolicy)
	{
		default: 
		case POLICY_TIMESHARE:[schedulingPolicyMatrix selectCellWithTag:0];
					break;
		case POLICY_FIXEDPRI: [schedulingPolicyMatrix selectCellWithTag:1];
					break;
	}

	[self setServerInfo];

	return self;
}

- setServerInfo
{
char buffer[1024];
char *tempDictVersion, *temp, *temp1;
int i;

	[serverVersionText setStringValue:[mySpeech serverVersion]];

	tempDictVersion = (char *) [mySpeech dictionaryVersion];
	if (tempDictVersion)
	{

		bzero(buffer,1024);
		temp = dindex(tempDictVersion, "V: ");
		if (temp)
		{
			temp+=3;
			temp1 = buffer;
			while (*temp!='\n')
				*(temp1++) = *(temp++);
		}
		else
		{
			strcpy(buffer,"Incompatible Version");
		}

		printf("Buffer = |%s|\n", buffer);

		[dictionaryVersionText setStringValue: buffer];

		bzero(buffer,1024);
		temp = dindex(tempDictVersion, "C: ");
		if (temp)
		{
			temp+=3;
			temp1 = buffer;
			while(*temp!='\000')
				*(temp1++) = *(temp++);
		}
		else
		{
			strcpy(buffer,"Incompatible Version");
		}

		printf("Buffer = |%s|\n", buffer);

		[compiledVersionText setStringValue: buffer];
	}
	[serverPIDText setIntValue: [mySpeech serverPID]];
	return self;
}

- newPriority:sender
{
	[machPriorityField setIntValue: [sender intValue]];
	return self;
}

- newTimeQuantum:sender
{
	[timeQuantumField setIntValue: [sender intValue]];
	return self;
}

- newTimeQuantumText:sender
{
int temp;
	temp = [sender intValue];
	if (temp<15)
		temp = 15;
	else
	if (temp>350)
		temp = 350;

	[sender setIntValue:temp];
	[timeQuantumSlider setIntValue:temp];

	return self;
}

- setValues:sender
{
	[mySpeech setPriority: [machPriorityField intValue]];
	[mySpeech setQuantum: [timeQuantumField intValue]];

	switch([[schedulingPolicyMatrix selectedCell] tag])
	{
		default:
		case 0: 
			[mySpeech setPolicy: POLICY_TIMESHARE];
			break;
		case 1: 
			[mySpeech setPolicy: POLICY_FIXEDPRI];
			break;

	}

	[mySpeech setSilencePrefill: [silencePrefillField intValue]];

	[mySpeech inactiveServerKill: [killSwitch state]];

	return self;
}

- newPrefill:sender
{
	[silencePrefillField setIntValue: [sender intValue]];
	return self;
}

- newPrefillText:sender
{
int temp;
	temp = [sender intValue];
	if (temp<1)
		temp = 1;
	else
	if (temp>5)
		temp = 5;

	[sender setIntValue:temp];
	[silencePrefillSlider setIntValue:temp];

	return self;
}

- newPolicy:sender
{
	switch([[sender selectedCell] tag])
	{
		default: 
		case 0: 
			break;
		case 1: 
			break;
	}
	return self;
}

- restartServer:sender
{
	[mySpeech requestServerRestart];
	mySpeech = [[TextToSpeech alloc] init];
	if (!mySpeech)
	{
		[connectPanel orderFront:self];
		sleep(5);
		mySpeech = [[TextToSpeech alloc] init];
		[connectPanel orderOut:self];
		if (!mySpeech)
		{
			NXRunAlertPanel ("Cannot connect",
				"Too many clients, or TTS_server cannot be started.",
				"OK", NULL, NULL);
  			exit(0);
		}

	}

	[self setServerInfo];
	
	return self;
}

@end
