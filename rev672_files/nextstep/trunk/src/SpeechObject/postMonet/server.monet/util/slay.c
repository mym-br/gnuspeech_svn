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

main(int argc, char **argv)
{
    FILE               *fin;
    char                buf[BUFSIZ];
    int                 pid;
    int                 mypid;
    int                 itspid;
    int                 n;
    static char        *ps = "exec /bin/ps -x";

    if (!(argc > 1)) {
        fprintf(stderr, "Usage: \n");
        fprintf(stderr, "\t%s [-a][-i][process name]\n", *argv);
        exit(1);
    }
    if ((fin = popen(ps, "r")) == NULL) {
        fprintf(stderr, "%s: can't run %s\n", *argv, ps);
        exit(1);
    }
    mypid = getpid();
    fgets(buf, BUFSIZ, fin);

    if (!(strcmp(argv[1], "-a"))) {     /* Kill everything except parent
                                         * process */
        itspid = getppid();
        while (fgets(buf, BUFSIZ, fin) != NULL) {
            sscanf(buf, "%d", &pid);
            if (pid != mypid && pid != itspid)
                kill(pid, SIGKILL);
        }
    } else if (!(strcmp(argv[1], "-i"))) {      /* Interactive kill */
        fprintf(stderr, "%s", buf);
        while (fgets(buf, BUFSIZ, fin) != NULL) {
            sscanf(buf, "%d", &pid);
            if (pid != mypid) {
                *(index(buf, '\n')) = '\00';
                fprintf(stderr, "%s ?", buf);   /* query for kill */
                if (gets(buf) != NULL && *buf == 'y')
                    kill(pid, SIGKILL);
                else if (*buf == 'q')
                    exit(0);
            }
        }
    } else
        while (fgets(buf, BUFSIZ, fin) != NULL) {       /* Kill only process
                                                         * listed on command
                                                         * line */
            for (n = 1; n < argc; n++) {
                sscanf(buf, "%d", &pid);
                if ((pid != mypid) && (dindex(buf, argv[n]) != NULL))
                    kill(pid, SIGKILL);
            }
        }
}

static inline char *dindex(char *buf, char *string)
{
    int                 len = strlen(string);

    for (; *buf; buf++)
        if (strncmp(buf, string, len) == 0)
            return (buf);
    return (NULL);
}
