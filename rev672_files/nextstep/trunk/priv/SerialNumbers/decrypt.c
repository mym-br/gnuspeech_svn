#include <stdio.h>

#define XOR16	0x6CB2
#define XOR32	0x5CA379D3
#define PRIME	1327673

//	1777
//	75323
//	1327673

void consistent();

main(argc, argv)
int argc;
char *argv[];
{
unsigned int i;
unsigned int temp, temp2;

	sscanf(argv[1], "%x", &temp);

//	printf("%x\n", temp);
	temp2 = revmunge(temp);
//	printf("%x\n", temp2);
	temp2^= XOR32;
//	printf("%x\n", temp2);

	temp2^=XOR16;

	if (temp2&0x00008000)
		printf("Developer Kit\n");
	else
		printf("User Kit\n");

	printf("Serial number %d\n", temp2&0x00007FFF);

	consistent(temp2&0x0000FFFF, temp);
}

void consistent(number, oldResult)
unsigned int number;
unsigned int oldResult;
{
unsigned int x1, x2, x3;
unsigned int y1;
unsigned int tempResult, result;

	y1 = number&0x0000FFFF;		/* 15 bits for space */

//	printf("Y1 = %x\n", y1);
	
	y1 ^= XOR16;			/* Xclusive or to jumble data a bit */

//	printf("XOR y1 = %x\n", y1);

	x1 = y1&0x000000FF;		/* Lower 8 bits */
	x2 = y1&0x0000FF00;		/* upper 8 bits */

//	printf("x1 = %x  x2 = %x\n", x1, x2);

	x3 = PRIME*x1*(x2>>8);		/* multiply for consistency check */

//	printf("x3 = %x\n", x3);

	tempResult = (x3&0xFFFF0000)|x2|x1;
	tempResult^=XOR32;
	result = munge(tempResult);

	if (result ==oldResult)
		printf("Number is consistent\n");
	else
		printf("*Number is NOT consistent\n");

}