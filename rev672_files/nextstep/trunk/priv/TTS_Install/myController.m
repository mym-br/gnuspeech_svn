
/* Generated by Interface Builder */

#import "myController.h"
#import <libc.h>
#import <appkit/TextField.h>
#import <objc/Object.h>
#import <appkit/Panel.h>
#import <defaults/defaults.h>

extern unsigned int getSeed();
extern void genBuffer();
extern int check_buffer();

#define CHECKSUM b3aa712a

int decrypt(seed, input, output)
unsigned int seed;
FILE *input, *output;
{
unsigned int buffer[256];
unsigned int in_buf[256], out_buf[256];
int i, bytes;

	genBuffer(seed, buffer);
	if (check_buffer(buffer) == 0) return(0);

	while( (bytes = fread(in_buf, 1, 1024, input))!=0)
	{
		bcopy(in_buf, out_buf, 1024);
		for (i = 0;i<bytes/4;i++)
		{
			out_buf[i] = (int) (in_buf[i]-buffer[i]);
		}
		if (fwrite(out_buf, 1, bytes, output) == 0) break;
	}
	return(1);
}

@implementation myController

- appDidInit:sender
{
char temp[128];

	sprintf(temp,"%x", gethostid());
	[hostid setStringValue:temp];
	return self;
}

- decrypt:sender
{
FILE *myPipe, *fp, *errors;
char appPath[256];
unsigned int tempPassword;
unsigned int seed;

	sscanf([password stringValue], "%x", &tempPassword);

	bzero(appPath, 256);
	strcpy(appPath, (char *) [self appDirectory]);
	strcat(appPath, "/TextToSpeech.Dev");

	fp = fopen(appPath, "r");
	if (fp == NULL)
	{
		NXRunAlertPanel("TTS Developer Installation", "Cannot open file named \"%s\".", "Ok", NULL, NULL, appPath);
		return self;
	}

	myPipe = popen("/usr/ucb/zcat | (cd /; tar -xf -)", "w");
	if (myPipe == NULL)
	{
		NXRunAlertPanel("TTS Developer Installation", "Cannot create pipe.", "Ok",NULL,NULL);
		return self;
	}

	seed = getSeed(tempPassword);
	if (decrypt(seed, fp, myPipe)==0) 
	{
		NXRunAlertPanel("TTS Developer Installation", "Incorrect Password.", "Ok",NULL,NULL);
		exit(0);
	}

	fclose(fp);
	pclose(myPipe);

	NXRunAlertPanel("TTS Developer Installation", "Installation Complete", "Ok", NULL, NULL);
	return self;
}

-(const char *) appDirectory
{
FILE *process;
char command[256];
char appDirectory[256];
char *suffix;

	strcpy(appDirectory, NXArgv[0]);
	if (appDirectory[0] == '/')
	{
	       /* if absolute path */
		if (suffix = rindex(appDirectory, '/'))
			*suffix = '\000';		   /* remove executable name */
	}
	else
	{
		sprintf(command, "which '%s'\n", NXArgv[0]);
		process = popen(command, "r");
		fscanf(process, "%s", appDirectory);
		pclose(process);
		if (suffix = rindex(appDirectory, '/'))
			*suffix = '\000';		   /* remove executable name */
		chdir(appDirectory);
		getwd(appDirectory);
	}
	return ( (const char *) appDirectory);
}


@end
