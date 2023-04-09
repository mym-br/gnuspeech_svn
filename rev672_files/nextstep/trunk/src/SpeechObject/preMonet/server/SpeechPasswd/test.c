#include <stdio.h>
#include <string.h>
#import "../headerFiles/andMap.h"

char password[24] = {"password is:XXXXXXXX"};

main(argc, argv)
int argc;
char *argv[];
{
unsigned int temp, seed, buffer[256];
int i;
char *data;
unsigned int *data1;

	data = index(password, ':');
	data1 = data+1;

	printf("compiled password = %x\n", *data1);
	printf("Date = %x\n", data1[1]);

	seed = getSeed(*data1);

	switch(seed^XORTHING)
	{
		case SEED1:
				printf("First seed found\n");
				break;
		case SEED2:
				printf("second seed found\n");
				break;
		case SEED3:
				printf("third seed found\n");
				break;
		default: 
			printf("Incorrect password\n");
			break;
	}

	seed = getSeed(data1[1]);

	switch((seed^XORTHING2)&0xFFF00000)
	{
		case SEEDDATE:
			printf("Date found = %x\n", (seed^XORTHING2)&0x000FFFFF);
			break;
		default:
			printf("Date seed incorrect\n");		
	}

	exit(0);
}
