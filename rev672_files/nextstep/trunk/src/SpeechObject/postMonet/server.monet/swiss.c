#include "mappingBuffer.h"

checkBuffer(buffer)
char *buffer;
{
int swissState = 1;
int swissMarker = 0;

int i = 0, len;

	len = strlen(buffer);
//	printf("Swiss hack:  Length = %d\n", len);
	while( i < len)
	{
//		printf(" S: %d  char: %d mBuffer: %d  >> ", swissState, buffer[i], mappingBuffer[buffer[i]]);
		swissState = swissTransitionTable[swissState][mappingBuffer[buffer[i]&0x7F]];
//		printf("New State = %d\n", swissState);
		switch(swissState)
		{
			case 4:
				swissMarker = i;
//				printf("Found ws The.  Marking e = %d\n", swissMarker);
				break;
			case 6: 
//				printf("Found ws The.  Marking e =>i  %d\n", swissMarker);
				buffer[swissMarker] = 'i';
				swissState = 0;
				swissMarker = 0;
				break;

		}
		i++;
	}
//	printf("%s\n", buffer);
}