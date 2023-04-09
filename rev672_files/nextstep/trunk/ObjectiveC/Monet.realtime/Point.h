
#import <objc/Object.h>

/*===========================================================================

	Author: Craig-Richard Taube-Schock
		Copyright (c) 1994, Trillium Sound Research Incorporated.
		All Rights Reserved.

=============================================================================
*/

@interface Point:Object
{
	double	value;		/* Value of the point */
	double	freeTime;	/* Free Floating time */
	id	expression;	/* Time of the point */
	int	type;		/* Which phone it is targeting */
	int	phantom;	/* Phantom point for place marking purposes only */
}

- init;

- setValue: (double) newValue;
- (double) value;

- (double) multiplyValueByFactor:(double) factor;
- (double) addValue:(double) newValue;

- setExpression: newExpression;
- expression;

- setFreeTime: (double) newTime;
- (double) freeTime;

- (double) getTime;

- setType: (int) newType;
- (int) type;

- setPhantom: (int) phantomFlag;
- (int) phantom;

- calculatePoints: (double *) ruleSymbols tempos: (double *) tempos phones: phones andCacheWith: (int) newCacheTag 
	toDisplay: displayList ;

- (double) calculatePoints: (double *) ruleSymbols tempos: (double *) tempos phones: phones andCacheWith: (int) newCacheTag
        baseline: (double) baseline delta: (double) delta min:(double) min max:(double) max 
	toEventList: eventList atIndex: (int) index;

- read:(NXTypedStream *)stream;
- write:(NXTypedStream *)stream;

@end
