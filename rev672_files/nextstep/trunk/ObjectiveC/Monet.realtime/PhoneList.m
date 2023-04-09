
#import "PhoneList.h"
#import "ParameterList.h"
#import "SymbolList.h"
#import <appkit/appkit.h>
#import <strings.h>

/*===========================================================================


===========================================================================*/

@implementation PhoneList

- (Phone *) findPhone: (const char *) phone
{
int i;
const char *temp;

	for (i = 0; i< numElements; i++)
	{
		temp = [ dataPtr[i] symbol];
		if (strcmp(temp, phone)==0)
			return dataPtr[i];
	}
	return nil;

}

- binarySearchPhone:(const char *) searchPhone index:(int *) index
{
int low, high, mid;
int test;

	low = 0;
	high = numElements-1;
	*index = 0;
	if (numElements == 0)	   /* Empty List */
		return nil;


	test = strcmp(searchPhone, [ (Phone *) dataPtr[low] symbol]);

	if (test == 0)		  /* First word in List */
		return dataPtr[low];
	else
	if (test<0)		     /* Belongs at the head of the list */
		return nil;

	*index = 1;

	if (numElements == 1)	   /* Only 1 item to test */
		return nil;

	*index = numElements;

	test = strcmp(searchPhone, [ (Phone *) dataPtr[high] symbol]);
	if (test == 0)		  /* Last word in List */
	{
		*index = high;
		return dataPtr[high];
	}
	else
	if (test>0)		     /* Belongs at the end of the list */
		return nil;

	while(1)
	{
		if ( (low+1) == high)
		{
			*index = high;
			break;
		}

		mid = (low+high)/2;

		test = strcmp(searchPhone, [ (Phone *) dataPtr[mid] symbol]);
		if (test == 0)
		{
			*index = mid;
			return dataPtr[mid];
		}
		else
		if (test > 0)
			low = mid;
		else
			high = mid;
	}
	return nil;
}

- findByName:(const char *) name
{
int dummy;
	if (name == NULL) return nil;
	return [self binarySearchPhone:name index:&dummy];
}

@end
