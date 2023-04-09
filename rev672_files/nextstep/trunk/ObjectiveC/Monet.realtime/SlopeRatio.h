
#import <objc/Object.h>
#import <objc/List.h>
#import "Slope.h"

/*===========================================================================

	Author: Craig-Richard Taube-Schock
		Copyright (c) 1994, Trillium Sound Research Incorporated.
		All Rights Reserved.

=============================================================================
*/

@interface SlopeRatio:Object
{
	List	*points;
	List	*slopes;
}

- init;

- setPoints: newList;
- points;
- setSlopes: newList;
- slopes;
- updateSlopes;

- (double) startTime;
- (double) endTime;


- calculatePoints: (double *) ruleSymbols tempos: (double *) tempos phones: phones andCacheWith: (int) newCacheTag 
        toDisplay: displayList ;

- (double) calculatePoints: (double *) ruleSymbols tempos: (double *) tempos phones: phones andCacheWith: (int) newCacheTag
	baseline: (double) baseline delta: (double) delta min: (double) min max:(double) max
	toEventList: eventList atIndex: (int) index;

- (double)totalSlopeUnits;
- displaySlopesInList: (List *) displaySlopes;


- free;

- read:(NXTypedStream *)stream;
- write:(NXTypedStream *)stream;

@end
