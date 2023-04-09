#import "ProcessManager.h"
#import <signal.h>

/*===========================================================================

	File: ProcessManager.m

	Purpose:  This file implements the following:
			o tty listing
			o user process listing 
			o tty logout

	Algorithm: This function opens a pipe to the UNIX command ps.

	Note: Because this file relies on the results of another execed
		program, there are potential security holes if this 
		program is run setuid.  Please do not run this program
		setuid unless you know what you are doing.

===========================================================================*/

id processManager;

@implementation ProcessManager


- init
{
	[super init];

	processManager = self;
	return self;
}

/*===========================================================================

	Method: readTTYProcesses: tty

	Purpose: To get process information about the terminal "tty" and 
		display	this information in the Text Object refered to by the 
		pointer "myTextObject"

===========================================================================*/
- readTTYProcesses: (char *) tty
{
FILE *fp;
char tempPipe[256], line[1024];
char buffer[20480];

	[myWindow makeKeyAndOrderFront:self];
	sprintf(tempPipe,"/bin/ps -auxwt%s | grep -v '/bin/ps'", tty);
	bzero(buffer, 20480);
	fp = popen(tempPipe, "r");
	if (fp == NULL)
		NXRunAlertPanel("TTY Process Listing", "Cannot open Pipe to ps", "Ok", NULL, NULL);
	else
	{
		while(fgets(line, 1024, fp))
			strcat(buffer,line);
		fclose(fp);
		[myTextObject setText:buffer];
	}

	return(self);

}

/*===========================================================================

	Method: readUserProcesses: name

	Purpose: To get process information about the user "name" and 
		display	this information in the Text Object refered to by the 
		pointer "myTextObject"

===========================================================================*/
- readUserProcesses: (char *) name
{
FILE *fp;
char tempPipe[256], line[1024];
char buffer[20480];

	[myWindow makeKeyAndOrderFront:self];
	sprintf(tempPipe,"/bin/ps -auxw | grep %s | grep -v '/bin/ps' | grep -v grep", name);
	bzero(buffer, 20480);
	strcpy(buffer,"USER       PID  %CPU %MEM VSIZE RSIZE TT STAT  TIME COMMAND\n");
	fp = popen(tempPipe, "r");
	if (fp == NULL)
		NXRunAlertPanel("TTY Process Listing", "Cannot open Pipe to ps", "Ok", NULL, NULL);
	else
	{
		while(fgets(line, 1024, fp))
			strcat(buffer,line);
		fclose(fp);
		[myTextObject setText:buffer];
	}

	return(self);

}


/*===========================================================================

	Method: logoutTTY: tty

	Purpose: To kill the csh (sh/tcsh) associated with terminal TTY. 

	Feedback: An alert panel is displayed if the terminal could not 
		be killed.

	NOTE:  Some people may want to run WhosOnFirst setuid root so that
		the person on the console can kill any user.  This is OK, 
		but make sure you understand the security implications 
		of running this program setuid root.

		(Personally, I wouldn't run this program setuid root). :-)

===========================================================================*/
- logoutTTY:(char *) ttyname
{
FILE *fp;
char tempPipe[256], line[1024];
int pid;

	sprintf(tempPipe,"/bin/ps -xt%s | grep 'sh)'", ttyname);
	fp = popen(tempPipe, "r");
	if (fp == NULL)
		NXRunAlertPanel("Logout TTY", "Cannot open Pipe to ps", "Ok", NULL, NULL);
	else
	{
		fgets(line, 1024, fp);
		fclose(fp);
		sscanf(line, "%d", &pid);
		if (kill(pid, SIGKILL)!=0)
			NXRunAlertPanel("Logout TTY", "Cannot kill terminal %s", "Ok", NULL, NULL, ttyname);
	}

	return(self);



}

@end
