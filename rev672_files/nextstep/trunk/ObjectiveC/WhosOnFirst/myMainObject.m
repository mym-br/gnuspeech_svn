#import "myMainObject.h"
#import <appkit/ScrollView.h>
#import <streams/streams.h>
#import <utmp.h>
#import <libc.h>
#import <sys/param.h>
#import <dpsclient/dpsNeXT.h>
#import "MailServer.h"

extern id infoManager;
int find();
void enter();
void clear_marks();
void remove_unmarked();

/*===========================================================================

	File: myMainObject.m
	Purpose:  This file replaces the file "myApp.m" in the previous 
		version.  3.0 doesn't like sub-classes of NXApp.
		This object does the work for determining who is on-line.
		This object receives the appDidInit method signals other 
		objects that this event occured.

	NOTE: All areas of code which deal with the TextToSpeech Kit have 
		been put under conditional compilation.  If you do not 
		have the TextToSpeech kit, simply comment out the flags 
		in the Makefile.preamble file and this code should compile
		for you.

===========================================================================*/


@implementation myMainObject

void who(DPSTimedEntry teNumber, double now, char *userData)

/* Call this function via the DPS Timed Entry */

{
struct utmp temp;			/* Utmp structure. See utmp.h */
char tempHost[MAXHOSTNAMELEN];

	clear_marks();					/* Clear marked */
	utmpFile = NXMapFile("/etc/utmp", NX_READONLY);	/* Map utmp file into memory */
	if (utmpFile == NULL)
	{
		exit(0);
	}
	while( NXRead(utmpFile, &temp, sizeof(struct utmp)) !=0 )	/* Read next entry */
	{
		if (temp.ut_name[0] != '\000')					/* Is is a real user? */
		{
			if (strlen(temp.ut_host)==0)
			{
				gethostname(tempHost, MAXHOSTNAMELEN);
				enter(temp.ut_line, temp.ut_name, tempHost);	/* Yes, enter or affirm in list */
			}
			else
				enter(temp.ut_line, temp.ut_name, temp.ut_host);	/* Yes, enter or affirm in list */
		}
	}
	remove_unmarked();					/* Remove all un-referenced entries in 
								   the list */

	NXCloseMemory(utmpFile, NX_FREEBUFFER);					/* Close utmp file */
}

-appDidInit:sender
{
#ifdef SPEECH
const char *appPath;
char dictPath[256];
id mailServer;
#endif
	/* Init Icon Position coordinates */
	nextX = nextY = 0;

	/* Icon Offset Coordinates */
	startX = startY = 23.4;

	/* Initialize List pointers */
	last = users = NULL;

	/* Fudge.  C calls seem to need this */
	c_self = self;

	DPSAddTimedEntry((double)5.0, (DPSTimedEntryProc) who, NULL, NX_BASETHRESHOLD);
	infoManager = localInfoMgr;

	/* Read in Defaults */
	[infoManager initDefaults];

#ifdef SPEECH
	/* Get application directory and set up TTS Kit application dictionary */
	appPath = [self appDirectory];
	strcpy(dictPath, appPath);
	strcat(dictPath, "/WhosOnFirst.preditor");

	/* Initialize the speech. Include the application dictionary.*/
	[infoManager initSpeech:dictPath];
	mailServer = [[MailServer alloc] init];
	[mailServer updateMail];
#endif

	[[Application workspace] beginListeningForApplicationStatusChanges];

	return(self);
}

/*===========================================================================

	Method: appDirectory
	Purpose: To determine the current working directory of this
		application.  The TextToSpeech application dictionary is
		located within WhosOnFirst.app.  To install this dictionary
		into the search path of the TextToSpeech Kit, we must provide
		the speech server with the full path.

===========================================================================*/

-(const char *) appDirectory
{
static char appDirectory[256];
FILE *process;
char command[256];
char *suffix;

	strcpy(appDirectory, NXArgv[0]);
	if (appDirectory[0] == '/')
	{               /* if absolute path */
		if (suffix = rindex(appDirectory, '/'))
			*suffix = '\000';                   /* remove executable name */
	} 
	else
	{
		sprintf(command, "which '%s'\n", NXArgv[0]);
		process = popen(command, "r");
		fscanf(process, "%s", appDirectory);
		pclose(process);
		if (suffix = rindex(appDirectory, '/'))
			*suffix = '\000';                   /* remove executable name */
		chdir(appDirectory);
		getwd(appDirectory);
	}
	return ( (const char *) appDirectory);
}

/*===========================================================================

	Method: newIconUser: name
		tty: ttystr
		host: hoststr
		xcoord: x
		ycoord: y

	Purpose: When a new user is detected, this method creats an icon
		for him/her and puts the utmp information within its own
		database.

===========================================================================*/

-newIconUser: (const char *)name tty: (const char *)ttystr host: (const char *) hoststr xcoord: (float)x ycoord: (float)y
{
NXRect windowRect;


#ifdef SPEECH
	/* Tell infoManager to Speak */
	[infoManager speakLoginMessage: name tty:ttystr host:hoststr];
#endif

	iconWindow = [Window alloc];			/* Get a window instance */


	/* Calulate Screen Coordinates */
	windowRect.origin.x = startX + 4.0 + 64.0 * x;
	windowRect.origin.y = startY + 0.0 + 64.0 * y;
	windowRect.size.height = windowRect.size.width = 64.0; /* Icon size 64x64 */

	/*Init the window content */
	[iconWindow initContent: &windowRect style: NX_PLAINSTYLE
		 backing: NX_BUFFERED buttonMask:0  defer: YES];

	/* Get an IconView Instance */
	icon = [[IconView alloc] init];

	/* Set IconView as the window's contentView */
	[[iconWindow setContentView: icon] free];

	[iconWindow setDelegate:icon];		/* Make view the window's delegate */
	[iconWindow makeFirstResponder:icon];	/* and first responder */

	[iconWindow addToEventMask:NX_MOUSEDOWNMASK];
	
	/* Add to window list */
	[iconWindow makeKeyAndOrderFront:self];	
 
	[icon iconSetName: name];		/* Set icon variables */
	[icon iconSetTty: ttystr];
	[icon iconSetHostName: hoststr];

	return iconWindow;
}

/*===========================================================================

	Method: terminate:sender

	Purpose:  The terminate method is sent here.  This object notifies 
		other objects that the program is about to terminate

===========================================================================*/

- terminate:sender
{
	[infoManager cleanUp];
	[owner terminate:sender];
	return self;
}

- app: sender applicationDidLaunch:(const char *)appName
{
	[infoManager notifyLaunch:appName];
	return self;
}

- app: sender applicationDidTerminate:(const char *)appName
{
	[infoManager notifyTerminate:appName];
	return self;
}

/*===========================================================================

	Function: enter (tty, name, hostname)

	Purpose:  When a new user is detected, information about his/her
		tty, login name, and hostname are kept in a small database.
		This function enters the user information into the 
		data structures.

	Structure: The data base is a simple linked-list.

===========================================================================*/

void enter(tty,name, hostname)
char *tty, *name, *hostname;
{
struct record *temp;


	if (find(tty, name)==0)		/* If new entry, malloc space and put in list */
	{
		temp = (struct record *) malloc(sizeof (struct record ));
		temp->next = NULL;

		/* New Icon */
		temp->windowPointer = [c_self newIconUser: name tty: tty host: hostname
					  xcoord: (float)(nextX) ycoord:(float) (nextY)];

		temp->x = (float)(nextX);	/* Position Icon in "dock" */
		temp->y = (float)(nextY);
		temp->marked = 1;	/* Mark icon as referenced */

		strcpy(temp->name, name);  		/* User name */
		temp->name[8] = '\000';
		strcpy(temp->tty, tty);	   		/* TTY name */
		strcpy(temp->hostname, hostname);	/* Hostname */

		if (last == NULL)	/* First entry in list (usually console) */
		{
			users = temp;
			last = temp;
		}
		else			/* Not first entry in list */
		{
			last->next = temp;
			last = temp;
		}

		nextY++;		/* Update coordinate for next icon */
		if (nextY>=12)
		{
			nextY = 0;
			nextX++;
		}
	}
}

void clear_marks()		/* Simply traverse list and clear "marked" item in struct */
{
struct record *temp;

	temp = users;
	while (temp!=NULL)
	{
		temp->marked = 0;
		temp = temp->next;
	}
}

void remove_unmarked()		/* Remove all items from the list which have not been referenced */
{
struct record *temp,*prev;

	nextX = nextY = 0;
	temp = users;
	prev = temp;
	while (temp!=NULL)
	{
		if (temp->marked == 0) 			/* Standard linked list removal algorithm */
		{

#ifdef SPEECH
			[infoManager speakLogoutMessage: temp->name tty:temp->tty host:temp->hostname];
#endif
			if (temp == users)		/* Remove head item */
			{
				users = temp->next;
				[temp->windowPointer free];
				free(temp);
				temp = users->next;
			}
			if (temp == last)		/* Remove last item */
			{
				last  = prev;
				prev -> next = NULL;
				[temp->windowPointer free];
				free(temp);
				temp = NULL;
			}
			else				/* Remove internal item */
			{
				prev->next = temp->next;
				[temp->windowPointer free];
				free(temp);
				temp = prev->next;
			}
		}
		else
		{
			temp->x = startX + 4.0 + 64.0 * (float) (nextX);	/* Calulate Screen Coordinates */
			temp->y = startY + 0.0 + 64.0 * (float) (nextY);

			/* Reposition icon to new location */
			[temp->windowPointer moveTo: temp->x : temp->y];
			[[temp->windowPointer contentView] display];

			nextY++;	/* Calculate next icon position */
			if (nextY>=12) 
			{
				nextY = 0;
				nextX++;
			}
			prev = temp;
			temp = temp->next;
		}
	}
}

int find(tty,name)	/* Return a 1 if record with "name" and "tty" exists in the list */
			/* Mark record as referenced so that it is not removed from the list */
char *tty,*name;
{
struct record *temp;

	temp = users;		/* Head of list */
	while(temp!=NULL)
	{
		if ((strncmp(temp->tty, tty,8)==0)&&(strncmp(temp->name,name,8) ==0))
		{
			temp->marked = 1;
			return(1);
		}
		temp = temp->next;
	}
	return(0);
}



@end
