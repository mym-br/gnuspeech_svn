
#import "CategoryNode.h"
#import <stdio.h>
#import <string.h>
#import <stdlib.h>

@implementation CategoryNode

- init
{
	symbol = NULL;
	comment = NULL;
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

- free
{
	if (symbol) 
		free(symbol);

	if (comment) 
		free(comment);

	[super free];

	return nil;
}

- freeIfNative
{
	if (native)
		[self free];
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

- read:(NXTypedStream *)stream
{
	[super read:stream];
	NXReadTypes(stream, "**i", &symbol, &comment, &native);
	return self;
}

- write:(NXTypedStream *)stream
{
	[super write:stream];
	NXWriteTypes(stream, "**i", &symbol, &comment, &native);
	return self;
}

@end
