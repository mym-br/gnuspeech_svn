#include <stdio.h>
#include "../headerFiles/andMap.h"

unsigned int munge_hostid();

unsigned int getSeedofHostid(password, hostId)
unsigned int password;
unsigned int hostId;
{
unsigned int temp;

//	printf("MUNGE: hostid %x passwd %x\n", hostId, password);
	temp = munge_hostid(hostId);
	temp = (temp*hostId) + password;

	return(temp);
}


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

	if (myHostId&BIT0) temp|=BIT4;
	if (myHostId&BIT1) temp|=BIT11;
	if (myHostId&BIT2) temp|=BIT19;
	if (myHostId&BIT3) temp|=BIT21;
	if (myHostId&BIT4) temp|=BIT12;
	if (myHostId&BIT5) temp|=BIT2;
	if (myHostId&BIT6) temp|=BIT25;

	if (myHostId&BIT8) temp|=BIT3;
	if (myHostId&BIT9) temp|=BIT13;
	if (myHostId&BIT10) temp|=BIT22;
	if (myHostId&BIT11) temp|=BIT9;
	if (myHostId&BIT12) temp|=BIT18;
	if (myHostId&BIT13) temp|=BIT26;
	if (myHostId&BIT14) temp|=BIT28;
	if (myHostId&BIT15) temp|=BIT1;
	if (myHostId&BIT16) temp|=BIT30;
	if (myHostId&BIT17) temp|=BIT6;
	if (myHostId&BIT18) temp|=BIT18;
	if (myHostId&BIT19) temp|=BIT23;
	if (myHostId&BIT20) temp|=BIT10;
	if (myHostId&BIT21) temp|=BIT29;
	if (myHostId&BIT22) temp|=BIT24;
	if (myHostId&BIT23) temp|=BIT17;
	if (myHostId&BIT24) temp|=BIT5;
	if (myHostId&BIT25) temp|=BIT27;
	if (myHostId&BIT26) temp|=BIT15;
	if (myHostId&BIT27) temp|=BIT14;
	if (myHostId&BIT28) temp|=BIT20;
	if (myHostId&BIT29) temp|=BIT16;
	if (myHostId&BIT30) temp|=BIT0;
	if (myHostId&BIT31) temp|=BIT8;

	return(temp);
}

//	printf("h:%x   m:%x\nh:%d   m:%d\n", myHostId&0xFFFFF, mungedId, myHostId&0xFFFFF, mungedId);
//	printf("s:%x   p:%x\n",  SEED, SEED-mungedId);
//	printf("h*m:%x   s-(h*m):%x\n", myHostId*mungedId, SEED-(myHostId*mungedId));
