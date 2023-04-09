
#import <objc/Object.h>
#import "FormulaExpression.h"

/*===========================================================================

	Author: Craig-Richard Taube-Schock
		Copyright (c) 1994, Trillium Sound Research Incorporated.
		All Rights Reserved.

=============================================================================
*/

@interface ProtoEquation:Object
{
	char 	*name;
	char 	*comment;
	id	expression;

	int     cacheTag;
	double  cacheValue;
}

- init;
- initWithName:(const char *) newName;

- setName:(const char *) newName;
- (const char *) name;

- setComment:(const char *) newComment;
- (const char *) comment;

- setExpression: newExpression;
- expression;

- (double) evaluate: (double *) ruleSymbols phones: phones andCacheWith: (int) newCacheTag;
- (double) evaluate: (double *) ruleSymbols tempos: (double *) tempos phones: phones andCacheWith: (int) newCacheTag;
- (double) cacheValue;

- free;

- read:(NXTypedStream *)stream;
- write:(NXTypedStream *)stream;

@end
