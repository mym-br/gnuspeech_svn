#import <stdio.h>
#import <c.h>
#ifdef V2
#import <mach.h>
#import <cthreads.h>
#import <defaults.h>
#endif
#ifdef V3
#import <mach/mach.h>
#import <mach/cthreads.h>
#import <defaults/defaults.h>
#endif
#import <signal.h>
#import <sys/time.h>
#import <appkit/nextstd.h>

#include <string.h>
#include <stdlib.h>
#include <sys/resource.h>
#import <sys/file.h>

#import "structs.h"
#import "serverDefaults.h"

extern int message_queue_empty;
extern struct _calc_info calc_info;

extern int SYSPriority, SYSPolicy, SYSQuantum, SYSPrefill, SYSKill;

extern int demoFlag;
extern int demoCount;

int hup()
{
	close_port();
	init_server();
	init_tone_groups();
	init_users();
}

time_out()
{
int checksum;

	init_users();			/* Remove dead objects */
	demoFlag = check_validity();

	if ((active_users() == 0) && (SYSKill))
	{
		close_port();
		NXLogError("TTS_Server: Speech server inactive.");
		exit(-1);
	}

}

main(argc, argv)
int argc;
char *argv[];
{
char *phones, buffer[48];
int index,length,temp, i, old_task, my_pid, ret, fd;
byte marked, salient, word, syllable;
struct itimerval ourTimer = {{30, 0},{30 ,0}}, oldTimer;
int priority, quantum, policy, prefill;
const char *systemPathPtr;
int checksum;

/*	NXLogError("TTS_Server: Server Started.");*/
#ifdef CLEAN_ENVIRONMENT
    if (ret = newenv("PATH=/bin:/usr/bin:/usr/ucb:/usr/local/bin",
		     "HOME",
		     "NAME",
		     "ORGANIZATION",
		     (char *) 0))
	perror("newenv");
#endif

	demoCount = 2;

	fd = open("/dev/tty", O_RDWR);
	ioctl(fd, TIOCNOTTY, 0);
	close (fd);
	setpgrp(getpid(), 0);

	signal(SIGHUP, hup);
	signal(SIGALRM, time_out);

	if (setitimer(ITIMER_REAL, &ourTimer, &oldTimer)!=0) NXLogError("TTS_Server: Could not set interval timer.\n");
	kill_servers();

        NXSetDefaultsUser(TTS_NXDEFAULT_ROOT_USER);
	if ((systemPathPtr = NXReadDefault(TTS_NXDEFAULT_OWNER,TTS_NXDEFAULT_SYSTEM_PATH))==NULL)
	{
		NXSetDefaultsUser((const char *) NXUserName());
		NXLogError("TTS server:  Could not find systemPath in root's defaults database.");
		exit(-2);
	}


	get_defaults_values();

//	printf("Defaults are: pri: %d quan: %d pol: %d prefill: %d\n", priority, quantum, policy, prefill);

	set_new_priority();

	if (argc>1)
	{
		/* Kill old server task */
		if (argv[1][1]=='k')
		{
			sscanf(argv[2], "%d", &old_task);
			kill(old_task, SIGKILL);
		}
	}

	init_all(systemPathPtr);
	demoFlag = check_validity();

	calc_info.identifier = (-1);
	while(1)
	{
		while(message_queue_empty)
		{
			poll_port(TRUE);
		}
		speak_next_message();
		calc_info.identifier = (-1);
	}

}


#ifdef CLEAN_ENVIRONMENT

 /*
  * newenv - sanitize process environment
  * 
  * Author: Wietse Venema (wietse@wzv.win.tue.nl), dept. of Mathematics and
  * Computing Science, Eindhoven University of Technology, The Netherlands.
  */

/* C library */

/* Attempt to unify the stdarg and varargs interfaces */

#ifdef __STDC__
#include <stdarg.h>
#define VARARGS(func,type,arg) func(type arg, ...)
#define VASTART(ap,type,name)  va_start(ap, name)
#else
#include <varargs.h>
#define VARARGS(func,type,arg) func(va_alist) va_dcl
#define VASTART(ap,type,name)  type name; va_start(ap); name = va_arg(ap, type)
#endif

/* findenv - look up environment entry */

static char *findenv(env, name)
char  **env;
register char *name;
{
    register char *cp;
    register int len = strlen(name);
    register char **cpp;

#define STREQ(x,y,l) (x[0] == y[0] && strncmp(x,y,l) == 0)

    for (cpp = env; cp = *cpp; cpp++)
	if (STREQ(name, cp, len) && cp[len] == '=')
	    return (cp);
    return (0);
}

/* newenv - set up limited environment */

int     VARARGS(newenv, char *, head)
{
    va_list ap;
    register char *item;
    register char **old;
    static char *new[] = {0};
    extern char **environ;

    VASTART(ap, char *, head);

    /*
     * Move original environment away and install an empty one. In principle,
     * this code should work even when we are called more than once. In
     * practice, most putenv() implementations maintain internal state and
     * have problems when the environment changes without their consent.
     */

    old = environ;
    environ = new;

    /*
     * Fill in the new environment. If "name=value" is given it is linked to
     * the new environment; if "name" is given its old environment entry is
     * linked to the new environment.
     */

    for (item = head; item; item = va_arg(ap, char *))
	if (strchr(item, '=') || (item = findenv(old, item)))
	    if (putenv(item))
		return (-1);
    return (0);
}


#endif

void get_defaults_values()
{
const char *priorityPtr, *quantumPtr, *policyPtr, *prefillPtr, *inactivePtr;
char buffer[48];

	if ((priorityPtr = NXReadDefault(TTS_NXDEFAULT_OWNER,TTS_NXDEFAULT_PRIORITY))==NULL)
	{
		bzero(buffer,48);		
		strcpy(buffer,"16");
		NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_PRIORITY, buffer);
		SYSPriority = 16;

	}
	else
	{
		SYSPriority = atoi(priorityPtr);
	}

	if ((quantumPtr = NXReadDefault(TTS_NXDEFAULT_OWNER,TTS_NXDEFAULT_QUANTUM))==NULL)
	{
		bzero(buffer,48);
		strcpy(buffer,"15");
		NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_QUANTUM, buffer);
		SYSQuantum = 15;

	}
	else
	{
		SYSQuantum = atoi(quantumPtr);
	}

	if ((prefillPtr = NXReadDefault(TTS_NXDEFAULT_OWNER,TTS_NXDEFAULT_PREFILL))==NULL)
	{
		bzero(buffer,48);
		strcpy(buffer,"1");
		NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_PREFILL, buffer);
		SYSPrefill = 1;

	}
	else
	{
		SYSPrefill = atoi(prefillPtr);
	}

	if ((policyPtr = NXReadDefault(TTS_NXDEFAULT_OWNER,TTS_NXDEFAULT_POLICY))==NULL)
	{
		bzero(buffer,48);
		strcpy(buffer,"POLICY_TIMESHARE");
		NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_POLICY, buffer);
		SYSPolicy = POLICY_TIMESHARE;

	}
	else
	{
		if (strcmp(policyPtr, "POLICY_FIXEDPRI") ==0)
			SYSPolicy = POLICY_FIXEDPRI;
		else
			SYSPolicy = POLICY_TIMESHARE;		
	}

	if ((inactivePtr = NXReadDefault(TTS_NXDEFAULT_OWNER,TTS_NXDEFAULT_INACTIVE))==NULL)
	{
		bzero(buffer,48);
		strcpy(buffer,"YES");
		NXWriteDefault(TTS_NXDEFAULT_OWNER, TTS_NXDEFAULT_INACTIVE, buffer);
		SYSKill = (int) TRUE;

	}
	else
	{
		if (strcmp(inactivePtr, "NO") == 0)
			SYSKill = FALSE;
		else
			SYSKill = TRUE;
	}

	NXUpdateDefaults();




	/* Set quantum to a reasonable value. */
	if (SYSQuantum<15)
		SYSQuantum = 15;
	else
	if (SYSQuantum >350)
		SYSQuantum = 350;

	if (SYSPriority>24)
		SYSPriority = 24;
	else
	if (SYSPriority<0)
		SYSPriority = 0;

}



set_new_priority()
{
kern_return_t           error;
struct host_sched_info  sched_info;
unsigned int            sched_count=HOST_SCHED_INFO_COUNT;
processor_set_t         default_set, default_set_priv;
thread_t		temp;

	/*
	 * Fix the default processor set to take a fixed priority thread.
	 */
	error=processor_set_default(host_self(), &default_set);
	if (error!=KERN_SUCCESS)
	{
		mach_error("Error calling processor_set_default()", error);
		exit(-3);
	}

	error=host_processor_set_priv(host_priv_self(), default_set, &default_set_priv);
	if (error != KERN_SUCCESS)
	{
		mach_error("Call to host_processor_set_priv() failed", error);
		exit(-4);
	}

	error=processor_set_policy_enable(default_set_priv, POLICY_FIXEDPRI);
	if (error != KERN_SUCCESS)
		mach_error("Error calling processor_set_policy_enable", error);

	/*
	 * Change the thread's scheduling policy to fixed priority.
	 */

//	error=thread_policy(thread_self(), POLICY_TIMESHARE, quantum);
	error=thread_policy(thread_self(), SYSPolicy, SYSQuantum);
	if (error != KERN_SUCCESS)
		mach_error("thread_policy() call failed", error);

	error = thread_max_priority(thread_self(), default_set_priv, 24);
	if (error != KERN_SUCCESS)
		mach_error("thread_priority() 1 call failed", error);

	error = thread_priority(thread_self(), SYSPriority, FALSE);
	if (error != KERN_SUCCESS)
		mach_error("thread_priority() 2 call failed", error);

	error = task_priority(task_self(), SYSPriority, FALSE);
	if (error != KERN_SUCCESS)
		mach_error("thread_priority() 4 call failed", error);

}

