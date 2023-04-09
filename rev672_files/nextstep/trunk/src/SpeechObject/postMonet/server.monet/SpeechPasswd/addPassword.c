#include <stdio.h>
#include <string.h>
#import <streams/streams.h>
#import "../headerFiles/andMap.h"

char demoBuffer[64] =
        {27, 190, 156, 200, 251, 1, 4, 36, 221, 198,
        10, 90, 67, 15, 99, 231, 105, 37, 51, 1,
        12, 197, 56, 100, 223, 100, 31, 136, 44, 45,
        101, 227, 231, 195, 186, 17, 250, 236, 201, 199,
        24, 21, 226, 254,
/* DemoMode */
        251, 1, 4, 36,
/* Reg hostid */
        221, 198, 27, 190,
/* password */
        156, 200, 251, 1,
/* Date Code */
        4, 36, 221, 198,
/* Checksum */
        27, 190, 156, 200};

long find_spot();

main(argc, argv)
int argc;
char *argv[];
{
unsigned int temp;
unsigned int temp1;
int i;
long seekPoint;
NXStream *fp;

	if ((argc<2)||(argc>3))
		exit(0);
	sscanf(argv[1], "%x", &temp);
	temp = temp^XORTHING;
	if (argc==3)
	{
		sscanf(argv[2], "%x", &temp1);
		temp1 = temp1^XORTHING2;
	}
	fp = NXMapFile("../out", NX_READWRITE);

	if (fp == NULL)
	{
		printf("Could not open binary file\n");
		exit(-1);
	}

	seekPoint = find_spot(fp);
	if (seekPoint)
	{
		printf("SeekPoint = %d\n", seekPoint);
		NXSeek(fp, seekPoint+8, NX_FROMSTART);
		NXWrite(fp, &temp, sizeof(int));
		NXWrite(fp, &temp1, sizeof(int));
		NXFlush(fp);
		NXSaveToFile(fp, "../out.new" );
	}
	else
	{
		printf("Could not insert password into file\n");
	}
	NXCloseMemory(fp, NX_FREEBUFFER);
	exit(0);
}

long find_spot(fp)
NXStream *fp;
{
char temp;
int index = 0;

	while (NXRead(fp, &temp, 1))
	{
//		printf("Index = %d temp = %c password[%d] = %c\n", index, temp, index, password[index]);
		if (temp == demoBuffer[index])
		{
			index++;
			if (index == 44)
			{
				printf("Found!\n");
				return NXTell(fp);
			}
		}
		else
		{
			index = 0;
			if (temp == demoBuffer[index])
				index++;
		}
	}
	
	return 0;
}