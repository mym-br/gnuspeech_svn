#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <string.h>

/*
 *           SLAY 
 * INTERACTIVE PROCESS KILLER 
 * 
 * Don't use this as root.
 * Written By David Jevans, fixed up by Vince DeMarco
 */

static inline char *dindex(char *buf, char *string);

kill_servers()
{
FILE            *fin;
char            buf[BUFSIZ];
int             pid;
int             mypid;
int             itspid;
int             n;
static char     *ps = "exec /bin/ps -x";
static char	*name = "TTS_Server";

	if ((fin = popen(ps, "r")) == NULL) 
	{
		fprintf(stderr, "can't run %s\n", ps);
		return(1);
	}
	mypid = getpid();
	fgets(buf, BUFSIZ, fin);

	while (fgets(buf, BUFSIZ, fin) != NULL)
	{
		sscanf(buf, "%d", &pid);
		if ((pid != mypid) && (dindex(buf, name) != NULL))
			kill(pid, SIGKILL);
	}
	return(0);
}

static inline char *dindex(char *buf, char *string)
{
int len = strlen(string);

	for (; *buf; buf++)
		if (strncmp(buf, string, len) == 0)
			return (buf);
		return (NULL);
}
