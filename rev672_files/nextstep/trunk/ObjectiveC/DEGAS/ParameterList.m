
#import "ParameterList.h"

/*===========================================================================

	This Class currently adds no functionality to the List class.
	However, it is planned that this object will provide sorting functions
	to the Phone class.

===========================================================================*/

@implementation ParameterList

- (Parameter *) findParameter: (const char *) symbol
{
int i;
char *temp;

	for (i = 0; i< numElements; i++)
	{
		temp = [ dataPtr[i] symbol];
		if (strcmp(temp, symbol)==0)
			return dataPtr[i];
	}
	return nil;

}

- addParameter: (const char *) newSymbol min:(float) minValue max:(float) maxValue def:(float) defaultValue
{
Parameter *tempParameter;

	tempParameter = [[Parameter alloc] initWithSymbol:newSymbol];
	[tempParameter setMinimum: minValue];
	[tempParameter setMaximum: maxValue];
	[tempParameter setDefaultValue: defaultValue];

	[self addObject: tempParameter];

	return self;
}

@end
