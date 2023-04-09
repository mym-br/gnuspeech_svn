
#import "PhoneList.h"

/*===========================================================================

	This Class currently adds no functionality to the List class.
	However, it is planned that this object will provide sorting functions
	to the Phone class.

===========================================================================*/

@implementation PhoneList

- (Phone *) findPhone: (const char *) phone
{
int i;
char *temp;

	for (i = 0; i< numElements; i++)
	{
		temp = [ dataPtr[i] symbol];
		if (strcmp(temp, phone)==0)
			return dataPtr[i];
	}
	return nil;

}

- addPhone: (const char *) phone
{
Phone *tempPhone;
int index;

	if ([self binarySearchPhone:phone index:&index])
		return nil;

	tempPhone = [[Phone alloc] initWithSymbol:phone];
	[[tempPhone categoryList] addNativeCategory: phone];

	[self insertObject: tempPhone at:index];

	return self;
}

- addPhoneObject: (Phone *) phone
{
int index;

	if ([self binarySearchPhone:[phone symbol] index:&index])
		return nil;

	[self insertObject: phone at:index];

	return self;
}

- binarySearchPhone:(const char *) searchPhone index:(int *) index
{
int low, high, mid;
int i, test;
char *temp;

	low = 0;
	high = numElements-1;
	*index = 0;
	if (numElements == 0)	   /* Empty List */
		return nil;


	test = strcmp(searchPhone, [ dataPtr[low] symbol]);

	if (test == 0)		  /* First word in List */
		return dataPtr[low];
	else
	if (test<0)		     /* Belongs at the head of the list */
		return nil;

	*index = 1;

	if (numElements == 1)	   /* Only 1 item to test */
		return nil;

	*index = numElements;

	test = strcmp(searchPhone, [ dataPtr[high] symbol]);
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

		test = strcmp(searchPhone, [ dataPtr[mid] symbol]);
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


@end
