#include <stdio.h>
#include "andMap.h"

#define SEED	2495323

unsigned int munge_hostid();

/*===========================================================================

	File: genpass.c
	Purpose: Given a hostid (in HEX) on the command line, this program
		 will generate the necessary decryption password.

	Compilation:  This program requires the function "mungeId".  This 
		function can be found in the file "munge.c".

===========================================================================*/

main(argc, argv)
int argc;
char *argv[];
{
unsigned int mungedId, password, i;

	if (argc != 2) usage(argv[0]);
	sscanf(argv[1],"%x", &i);
	mungedId = munge_hostid(i);
	password = SEED-(i*mungedId);
	printf("hostid:%x   password:%x\n", i, password);

	printf("Seed = %x\n", getSeed(password));

	exit(0);
}

usage(string)
char *string;
{
	printf("Usage: %s hostId\n", string);
	exit(0);
}
