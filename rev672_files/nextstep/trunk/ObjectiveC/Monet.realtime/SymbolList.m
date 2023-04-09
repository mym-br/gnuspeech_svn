
#import "SymbolList.h"


/*===========================================================================

	This Class currently adds no functionality to the List class.
	However, it is planned that this object will provide sorting functions
	to the CategoryNode class.

===========================================================================*/

@implementation SymbolList

-findSymbol:(const char *) searchSymbol
{
int i;
const char *temp;


	for (i = 0; i<numElements; i++)
	{
		temp = [ dataPtr[i] symbol];
		if (strcmp(temp, searchSymbol)==0)
		{
			return dataPtr[i];
		}
	}
	return nil;
}

-(int) findSymbolIndex:(const char *) searchSymbol
{
int i;
const char *temp;


	for (i = 0; i<numElements; i++)
	{
		temp = [ dataPtr[i] symbol];
		if (strcmp(temp, searchSymbol)==0)
		{
			return i;
		}
	}
	return (-1);
}

@end
