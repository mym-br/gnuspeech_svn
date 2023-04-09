
#import "ParameterList.h"
#import <string.h>

#define DEFAULT_MIN	100.0
#define DEFAULT_MAX	1000.0

/*===========================================================================

	This Class currently adds no functionality to the List class.
	However, it is planned that this object will provide sorting functions
	to the Phone class.

===========================================================================*/

@implementation ParameterList

- (Parameter *) findParameter: (const char *) symbol
{
int i;
const char *temp;

	for (i = 0; i< numElements; i++)
	{
		temp = [ dataPtr[i] symbol];
		if (strcmp(temp, symbol)==0)
			return dataPtr[i];
	}
	return nil;

}

- (int) findParameterIndex: (const char *) symbol
{
int i;
const char *temp;

	for (i = 0; i< numElements; i++)
	{
		temp = [ dataPtr[i] symbol];
		if (strcmp(temp, symbol)==0)
			return i;
	}
	return (-1);

}

- (double) defaultValueFromIndex:(int) index
{
	return [[self objectAt:index] defaultValue];
}

- (double) minValueFromIndex:(int) index
{
	return [[self objectAt:index] minimum];
}

- (double) maxValueFromIndex:(int) index
{
	return [[self objectAt:index] maximum];
}


@end
