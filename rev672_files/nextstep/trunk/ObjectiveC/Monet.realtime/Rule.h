
#import <objc/Object.h>
#import <objc/List.h>
#import "BooleanExpression.h"
#import "CategoryList.h"

/*===========================================================================

	Author: Craig-Richard Taube-Schock
		Copyright (c) 1994, Trillium Sound Research Incorporated.
		All Rights Reserved.

=============================================================================
*/

@interface Rule:Object
{
	List *parameterProfiles;
	List *metaParameterProfiles;
	List *expressionSymbols;

	id specialProfiles[16];

	BooleanExpression *expressions[4];
	char *comment;

}

- init;
- free;

- getExpressionNumber:(int) index;
- (int) numberExpressions;
- (int) matchRule: (List *) categories;

- getExpressionSymbol:(int) index;
- evaluateExpressionSymbols:(double *) buffer tempos: (double *) tempos phones: phones withCache: (int) cache;

- parameterList;
- metaParameterList;
- symbols;

- getSpecialProfile:(int) index;
- setSpecialProfile:(int) index to:special;

- read:(NXTypedStream *)stream;
- write:(NXTypedStream *)stream;

@end


