
#import "RuleList.h"
#import <appkit/Application.h>
#import <string.h>

/*===========================================================================

===========================================================================*/
//- findRule:(const char *) searchSymbol;


@implementation RuleList

- findRule: (List *) categories index:(int *) index
{
int i;
	for(i = 0 ; i < numElements ; i++)
	{
		if ([(Rule *) dataPtr[i] numberExpressions]<=[categories count])
			if ([(Rule *) dataPtr[i] matchRule: categories])
			{
				*index = i;
				return dataPtr[i];
			}
	}
	return [self lastObject];
}

- read:(NXTypedStream *)stream
{
	[super read:stream];

	return self;
}

- write:(NXTypedStream *)stream
{
	[super write:stream];
	return self;
}

@end
