 /*
  * newenv - sanitize process environment
  * 
  * Author: Wietse Venema (wietse@wzv.win.tue.nl), dept. of Mathematics and
  * Computing Science, Eindhoven University of Technology, The Netherlands.
  */

/* C library */

#ifdef __STDC__
#include <string.h>
#include <stdlib.h>
#else
extern char *strchr();
#endif

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

#ifdef TEST

main()
{
    int     ret;

    if (ret = newenv("PATH=/bin:/usr/bin:/usr/ucb:/usr/local/bin",
		     "HOME",
		     "NAME",
		     "ORGANIZATION",
		     (char *) 0))
	perror("newenv");

    system("printenv");
    return (ret);
}

#endif
