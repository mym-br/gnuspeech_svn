
#import "CategoryList.h"

/*===========================================================================

	This Class currently adds no functionality to the List class.
	However, it is planned that this object will provide sorting functions
	to the CategoryNode class.

===========================================================================*/

@implementation CategoryList

-findSymbol:(char *) searchSymbol
{
int i;
char *temp;

	for (i = 0; i<numElements; i++)
	{
		temp = [ dataPtr[i] symbol];
		if (strcmp(temp, searchSymbol)==0)
			return dataPtr[i];
	}
	return nil;
}

- addCategory:(const char *) newCategory
{
CategoryNode *tempCategory;

	tempCategory = [[CategoryNode alloc] initWithSymbol: newCategory];
	[self addObject: tempCategory];

	return self;
}

- addNativeCategory:(const char *) newCategory
{
CategoryNode *tempCategory;

	tempCategory = [[CategoryNode alloc] initWithSymbol: newCategory];
	[tempCategory setNative: 1];
	[self addObject: tempCategory];

	return self;
}

- freeNativeCategories
{
int i;

	return self;

	for (i = numElements-1; i>=0; i--)
	{
		printf("|%s| %d ... ", [dataPtr[i] symbol], [dataPtr[i] native]);
		if ([dataPtr[i] native])
		{
			printf("Freed\n");
			[dataPtr[i] free];
			dataPtr[i] = nil;
		}
		else
			printf("NOT Freed\n");
	}

	return self;
}

@end
