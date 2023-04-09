#include <stdio.h>
#include <string.h>
#include "rPrimes.h"

#define CHECKSUM 0xb3aa712a

int check_buffer(buffer)
unsigned int *buffer;
{
int i;
unsigned int checksum;

	checksum = 0;
	for (i = 0;i<256;i++)
		checksum += buffer[i];

	return(checksum == CHECKSUM);


}

void genBuffer(seed, buffer)
unsigned int seed;
unsigned int *buffer;
{
int i;

	bzero(buffer,sizeof(unsigned int)*256);
	buffer[0] = seed;
	for(i = 1; i<256; i++)
		buffer[i] = buffer[i-1]*primeList[i%5];

}

#ifdef TEST
main(argc, argv)
int argc;
char *argv[];
{
unsigned int temp, seed, buffer[256];
int i;

	if (argc!=2) exit(0);
	sscanf(argv[1], "%x", &temp);

	seed = getSeed(temp);
	genBuffer(seed, buffer);

	for (i = 0;i<256;i++)
		printf("%x, ", buffer[i]);

	printf("CheckBuffer = %d\n", check_buffer(buffer));

	exit(0);
}
#endif