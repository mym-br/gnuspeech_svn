
#import "CategoryNode.h"
#import <stdio.h>
#import <string.h>
#import <stdlib.h>

@implementation CategoryNode

- init
{
	symbol = NULL;
	native = 0;
	return self;
}

- initWithSymbol:(const char *) newSymbol
{
	[self setSymbol: newSymbol];
	return self;
}

- setSymbol:(const char *) newSymbol
{
int len;
	if (symbol)
		free(symbol);

	len = strlen(newSymbol);
	symbol = (char *) malloc(len+1);
	strcpy(symbol, newSymbol);

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
	[super free];

	return nil;
}

- setNative:(int) isNative
{
	native = isNative;
	return self;
}

- (int) native
{
	return native;
}

@end
