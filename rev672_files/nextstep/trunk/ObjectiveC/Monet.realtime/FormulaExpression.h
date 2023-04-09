
#import <objc/Object.h>
#import "FormulaSymbols.h"

/*===========================================================================

	Author: Craig-Richard Taube-Schock
		Copyright (c) 1994, Trillium Sound Research Incorporated.
		All Rights Reserved.

=============================================================================
*/

@interface FormulaExpression:Object
{
	int	operation;
	int	numExpressions;
	int	maxExpressions;
	int	precedence;
	id	*expressions;

	/* Cached evaluation */
	int	cacheTag;
	double	cacheValue;
}

- init;
- free;

- (double) evaluate: (double *) ruleSymbols phones: phones;
- (double) evaluate: (double *) ruleSymbols tempos: (double *) tempos phones: phones;

- setOperation:(int) newOp;
- (int) operation;

- setPrecedence:(int) newPrec;
- (int) precedence;

- addSubExpression: newExpression;

- setOperandOne: operand;
- operandOne;

- setOperandTwo: operand;
- operandTwo;


- optimize;
- optimizeSubExpressions;

- (int) maxExpressionLevels;
- (int) maxPhone;
- expressionString:(char *) string;

- (char *) opString;

- read:(NXTypedStream *)stream;
- write:(NXTypedStream *)stream;

@end
