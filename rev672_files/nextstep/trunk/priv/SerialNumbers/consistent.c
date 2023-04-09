#include <stdio.h>
#include "andMap.h"

#define XOR16	0x6CB2
#define XOR32	0x5CA379D3
#define PRIME	1327673

int consistent(number)
unsigned int number;
{
unsigned int x1, x2, x3;
unsigned int y1;
unsigned int tempResult, result;
unsigned int temp, temp2;

	temp2 = revmunge(number);
	temp2^= XOR32;
	temp2^=XOR16;

	y1 = temp2&0x0000FFFF;		/* 15 bits for space */

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

	if (result == number)
		return (1);
	else
		return(0);

}

unsigned int munge(input)
long input;
{
unsigned int temp = 0;

	if (input&BIT0) temp|= BIT18;
	if (input&BIT1) temp|= BIT3;
	if (input&BIT2) temp|= BIT9;
	if (input&BIT3) temp|= BIT13;
	if (input&BIT4) temp|= BIT14;
	if (input&BIT5) temp|= BIT31;
	if (input&BIT6) temp|= BIT29;
	if (input&BIT7) temp|= BIT2;
	if (input&BIT8) temp|= BIT27;
	if (input&BIT9) temp|= BIT19;
	if (input&BIT10) temp|= BIT6;
	if (input&BIT11) temp|= BIT26;
	if (input&BIT12) temp|= BIT24;
	if (input&BIT13) temp|= BIT12;
	if (input&BIT14) temp|= BIT7;
	if (input&BIT15) temp|= BIT22;
	if (input&BIT16) temp|= BIT21;
	if (input&BIT17) temp|= BIT1;
	if (input&BIT18) temp|= BIT28;
	if (input&BIT19) temp|= BIT15;
	if (input&BIT20) temp|= BIT20;
	if (input&BIT21) temp|= BIT25;
	if (input&BIT22) temp|= BIT23;
	if (input&BIT23) temp|= BIT0;
	if (input&BIT24) temp|= BIT8;
	if (input&BIT25) temp|= BIT16;
	if (input&BIT26) temp|= BIT10;
	if (input&BIT27) temp|= BIT5;
	if (input&BIT28) temp|= BIT30;
	if (input&BIT29) temp|= BIT4;
	if (input&BIT30) temp|= BIT11;
	if (input&BIT31) temp|= BIT17;

	return(temp);
}


unsigned int revmunge(input)
long input;
{
unsigned int temp = 0;

//	if (input&BIT0) temp|= 
//	if (input&BIT1) temp|= 
	if (input&BIT2) temp|= BIT7;
	if (input&BIT3) temp|= BIT1;
//	if (input&BIT4) temp|= 
//	if (input&BIT5) temp|= 
	if (input&BIT6) temp|= BIT10;
	if (input&BIT7) temp|= BIT14;
//	if (input&BIT8) temp|= 
	if (input&BIT9) temp|= BIT2;
//	if (input&BIT10) temp|= 
//	if (input&BIT11) temp|= 
	if (input&BIT12) temp|= BIT13;
	if (input&BIT13) temp|= BIT3;
	if (input&BIT14) temp|= BIT4;
//	if (input&BIT15) temp|= 
//	if (input&BIT16) temp|= 
//	if (input&BIT17) temp|= 
	if (input&BIT18) temp|= BIT0;
	if (input&BIT19) temp|= BIT9;
//	if (input&BIT20) temp|= 
//	if (input&BIT21) temp|= 
	if (input&BIT22) temp|= BIT15;
//	if (input&BIT23) temp|= 
	if (input&BIT24) temp|= BIT12;
//	if (input&BIT25) temp|= 
	if (input&BIT26) temp|= BIT11;
	if (input&BIT27) temp|= BIT8;
//	if (input&BIT28) temp|= 
	if (input&BIT29) temp|= BIT6;
//	if (input&BIT30) temp|= 
	if (input&BIT31) temp|= BIT5;

	return(temp);
}
