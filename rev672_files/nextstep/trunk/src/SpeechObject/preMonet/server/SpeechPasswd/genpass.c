#include <stdio.h>
#include "../headerFiles/andMap.h"

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
unsigned int date;

	if ((argc<2)||(argc>3))
		usage(argv[0]);
	sscanf(argv[1],"%x", &i);
	if (argc==3)
	{
		sscanf(argv[2],"%x", &date);
		date = date&0x000FFFFF;
	}

	mungedId = munge_hostid(i);
	password = (SEED1^XORTHING)-(i*mungedId);
	printf("hostid:%x\n", i, password);
	printf("seed: %x password:%x  Original seed: %x\n", getSeed(password)^XORTHING, password, SEED1);
	password = (SEED2^XORTHING)-(i*mungedId);
	printf("\nSeed2:%x   password:%x  Original seed: %x\n", getSeed(password)^XORTHING, password, SEED2);
	password = (SEED3^XORTHING)-(i*mungedId);
	printf("\nSeed3:%x   password:%x  Original seed: %x\n", getSeed(password)^XORTHING, password, SEED3);

	password = ((SEEDDATE|date)^XORTHING2)-(i*mungedId);
	printf("\nDate Seed: %x  password: %x  Original seed: %x\n", getSeed(password), password, SEEDDATE|date);

	exit(0);
}

usage(string)
char *string;
{
	printf("Usage: %s hostId [dateString]\n", string);
	exit(0);
}
