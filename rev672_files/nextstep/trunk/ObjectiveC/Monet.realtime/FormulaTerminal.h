
#import <objc/Object.h>
#import "Symbol.h"

/*===========================================================================

	Author: Craig-Richard Taube-Schock
		Copyright (c) 1994, Trillium Sound Research Incorporated.
		All Rights Reserved.

=============================================================================
*/

#define RULEDURATION    (-2)
#define BEAT		(-3)
#define MARK1		(-4)
#define MARK2		(-5)
#define MARK3		(-6)
#define TEMPO0		(-7)
#define TEMPO1		(-8)
#define TEMPO2		(-9)
#define TEMPO3		(-10)


@interface FormulaTerminal:Object
{
	Symbol	*symbol;
	double	value;
	int	whichPhone;
	int	precedence;

	int     cacheTag;
	double  cacheValue;

}

- init;

- setSymbol:newSymbol;
- symbol;

- setValue:(double) newValue;
- (double) value;

- setWhichPhone:(int) newValue;
- (int) whichPhone;

- setPrecedence: (int) newPrec;
- (int) precedence;

- (double) evaluate:(double *) ruleSymbols phones: phones;
- (double) evaluate:(double *) ruleSymbols tempos: (double *) tempos  phones: phones;

- optimize;
- optimizeSubExpressions;

- (int) maxExpressionLevels;
- (int) maxPhone;
- expressionString:(char *) string;

- read:(NXTypedStream *)stream;
- write:(NXTypedStream *)stream;


@end
