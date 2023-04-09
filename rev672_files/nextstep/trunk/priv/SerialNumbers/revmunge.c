#include <stdio.h>
#include "andMap.h"

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

/*
0  18
1  3
2  9
3  13
4  14
5  31
6  29
7  2
8  27
9  19
10  6
11  26
12  24
13  12
14  7
15  22
16  21
17  1
18  28
19  15
20  20
21  25
22  23
23  0
24  8
25  16
26  10
27  5
28  30
29  4
30  11
31  17
*/
//	printf("h:%x   m:%x\nh:%d   m:%d\n", input&0xFFFFF, mungedId, input&0xFFFFF, mungedId);
//	printf("s:%x   p:%x\n",  SEED, SEED-mungedId);
//	printf("h*m:%x   s-(h*m):%x\n", input*mungedId, SEED-(input*mungedId));
