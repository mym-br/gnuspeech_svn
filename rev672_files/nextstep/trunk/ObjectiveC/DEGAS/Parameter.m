
#import "Parameter.h"
#import <stdio.h>
#import <string.h>
#import <stdlib.h>

@implementation Parameter

- init
{
	parameterSymbol = NULL;

	minimum = 0.0;
	maximum = 0.0;
	defaultValue = 0.0;
	
	return self;
}

- initWithSymbol:(const char *) newSymbol
{
	[self init];
	[self setSymbol:newSymbol];
	return self;
}

- free
{
	if (parameterSymbol) 
		free(parameterSymbol);
	[super free];

	return nil;
}

- setSymbol:(char *) newSymbol
{
int len;

	if (parameterSymbol)
		free(parameterSymbol);

	len = strlen(newSymbol);
	parameterSymbol = (char *) malloc(len+1);
	strcpy(parameterSymbol, newSymbol);

	return self;
}

- (const char *) symbol
{
	return (parameterSymbol);
}

- setMinimum: (float) newMinimum
{
	minimum = newMinimum;
	return self;
}

- (float) minimum
{
	return minimum;
}

- setMaximum: (float) newMaximum
{
	maximum = newMaximum;
	return self;
}

- (float) maximum
{
	return maximum;
}

- setDefaultValue: (float) newDefault
{
	defaultValue = newDefault;
	return self;
}

- (float) defaultValue
{
	return defaultValue;
}

@end
