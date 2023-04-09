#include <stdio.h>
#include "andMap.h"

#define SEED	2495323

unsigned int munge_hostid();

unsigned int getSeed(password)
unsigned int password;
{
long myHostId = gethostid();
unsigned int temp;

	temp = munge_hostid(myHostId);
	temp = (temp*myHostId) + password;

	return(temp);
}

unsigned int munge_hostid(myHostId)
long myHostId;
{
unsigned int temp = 0;

	if (myHostId&BIT0) temp|=BIT17;
	if (myHostId&BIT1) temp|=BIT9;
	if (myHostId&BIT2) temp|=BIT5;
	if (myHostId&BIT3) temp|=BIT8;
	if (myHostId&BIT4) temp|=BIT11;
	if (myHostId&BIT5) temp|=BIT7;
	if (myHostId&BIT6) temp|=BIT2;
	if (myHostId&BIT7) temp|=BIT19;
	if (myHostId&BIT8) temp|=BIT6;
	if (myHostId&BIT9) temp|=BIT0;
	if (myHostId&BIT10) temp|=BIT15;
	if (myHostId&BIT11) temp|=BIT16;
	if (myHostId&BIT12) temp|=BIT13;
	if (myHostId&BIT13) temp|=BIT10;
	if (myHostId&BIT14) temp|=BIT17;
	if (myHostId&BIT15) temp|=BIT1;
	if (myHostId&BIT16) temp|=BIT4;
	if (myHostId&BIT17) temp|=BIT14;
	if (myHostId&BIT18) temp|=BIT12;
	if (myHostId&BIT19) temp|=BIT3;

	return(temp);
}

//	printf("h:%x   m:%x\nh:%d   m:%d\n", myHostId&0xFFFFF, mungedId, myHostId&0xFFFFF, mungedId);
//	printf("s:%x   p:%x\n",  SEED, SEED-mungedId);
//	printf("h*m:%x   s-(h*m):%x\n", myHostId*mungedId, SEED-(myHostId*mungedId));
