
#import "ProtoEquation.h"
#import <stdio.h>
#import <string.h>
#import <stdlib.h>

@implementation ProtoEquation

- init
{
	name = NULL;
	comment = NULL;
	expression = nil;
	return self;
}

- initWithName:(const char *) newName
{
	[self setName: newName];
	return self;
}

- setName:(const char *) newName
{
int len;
	if (name)
		free(name);

	len = strlen(newName);
	name = (char *) malloc(len+1);
	strcpy(name, newName);

	return self;
}

- (const char *) name
{
	return( (const char *) name);
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

- setExpression: newExpression
{
	expression = newExpression;
	return self;
}

- expression
{
	return expression;
}

- (double) evaluate: (double *) ruleSymbols tempos: (double * ) tempos phones: phones andCacheWith: (int) newCacheTag
{
	if (newCacheTag != cacheTag)
	{
		cacheTag = newCacheTag;
		cacheValue = [expression evaluate: ruleSymbols tempos: tempos phones: phones];
	}
	return cacheValue;

}
- (double) evaluate: (double *) ruleSymbols phones: phones andCacheWith: (int) newCacheTag
{
	if (newCacheTag != cacheTag)
	{
		cacheTag = newCacheTag;
		cacheValue = [expression evaluate: ruleSymbols phones: phones];
	}
	return cacheValue;
}

- (double) cacheValue
{
	return cacheValue;
}

- free
{
	if (name) 
		free(name);

	if (comment) 
		free(comment);

	if (expression)
		[expression free];

	[super free];

	return nil;
}

- read:(NXTypedStream *)stream
{
	[super read:stream];

	cacheTag = 0;
	cacheValue = 0.0;

	NXReadTypes(stream, "**", &name, &comment);
	expression = NXReadObject(stream);

	return self;
}

- write:(NXTypedStream *)stream
{
	[super write:stream];
	NXWriteTypes(stream, "**", &name, &comment);
	NXWriteObject(stream, expression);

	return self;
}

@end
