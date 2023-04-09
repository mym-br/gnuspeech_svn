
#import "Parameter.h"
#import <stdio.h>
#import <string.h>
#import <stdlib.h>

@implementation Parameter

- init
{
	parameterSymbol = NULL;
	comment = NULL;

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

	if (comment)
		free(comment);

	[super free];

	return nil;
}

- setSymbol:(const char *) newSymbol
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

- setComment:(const char *) newComment
{
int len;

	if (comment)
		free(comment);

	len = strlen(newComment);
	comment = (char *) malloc(len+1);
	strcpy(comment, newComment);

	return self;
}

- (const char *) comment
{
	return comment;
}

- setMinimum: (double) newMinimum
{
	minimum = newMinimum;
	return self;
}

- (double) minimum
{
	return minimum;
}

- setMaximum: (double) newMaximum
{
	maximum = newMaximum;
	return self;
}

- (double) maximum
{
	return maximum;
}

- setDefaultValue: (double) newDefault
{
	defaultValue = newDefault;
	return self;
}

- (double) defaultValue
{
	return defaultValue;
}

- read:(NXTypedStream *)stream
{
	[super read:stream];
	NXReadTypes(stream, "**ddd", &parameterSymbol, &comment, &minimum, &maximum, &defaultValue);
	return self;
}

- write:(NXTypedStream *)stream
{
	[super write:stream];
	NXWriteTypes(stream, "**ddd", &parameterSymbol, &comment, &minimum, &maximum, &defaultValue);
	return self;
}



@end
