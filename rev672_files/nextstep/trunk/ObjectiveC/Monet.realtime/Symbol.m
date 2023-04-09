
#import "Symbol.h"
#import <stdio.h>
#import <string.h>
#import <stdlib.h>

@implementation Symbol

- init
{
	symbol = NULL;
	comment = NULL;

	minimum = 0.0;
	maximum = 0.0;
	defaultValue = 0.0;

	return self;
}

- (const char *) symbol
{
	return( (const char *) symbol);
}

- free
{
	if (symbol) 
		free(symbol);
	if (comment)
		free(comment);

	[super free];

	return nil;
}

- (double) minimum
{
	return minimum;
}

- (double) maximum
{
	return maximum;
}

- (double) defaultValue
{
	return defaultValue;
}

- read:(NXTypedStream *)stream
{
	[super read:stream];
	NXReadTypes(stream, "**ddd", &symbol, &comment, &minimum, &maximum, &defaultValue);
	return self;
}

- write:(NXTypedStream *)stream
{
	[super write:stream];
	NXWriteTypes(stream, "**ddd", &symbol, &comment, &minimum, &maximum, &defaultValue);
	return self;
}


@end
