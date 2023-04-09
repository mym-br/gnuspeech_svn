#include <stdio.h>

#define XOR16	0x6CB2
#define XOR32	0x5CA379D3
#define PRIME	1327673

//	1777
//	75323
//	1327673

main()
{
unsigned int i;
int temp, temp2;

	for (i = 0; i<32768; i++)
	{
		temp = encrypt(i, 0);
		printf("%x	User %d\n", temp, i);
	}

	for (i = 0; i<32768; i++)
	{
		temp = encrypt(i, 1);
		printf("%x	Dev %d\n", temp, i);
	}

}

encrypt(number, dev)
unsigned int number;
int dev;			/* Developer kit? */
{
unsigned int x1, x2, x3;
unsigned int y1;
unsigned int tempResult, result;

	y1 = number&0x00007FFF;		/* 15 bits for space */
	if (dev)
		y1 |=0x00008000;	/* Or in developer kit bit */

	
	y1 ^= XOR16;			/* Xclusive or to jumble data a bit */


	x1 = y1&0x000000FF;		/* Lower 8 bits */
	x2 = y1&0x0000FF00;		/* upper 8 bits */


	x3 = PRIME*x1*(x2>>8);		/* multiply for consistency check */


	tempResult = (x3&0xFFFF0000)|x2|x1;
	tempResult^=XOR32;

	result = munge(tempResult);

	return result;
}