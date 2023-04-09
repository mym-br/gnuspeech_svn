
#import <objc/Object.h>

/*===========================================================================

	Author: Craig-Richard Taube-Schock
		Copyright (c) 1994, Trillium Sound Research Incorporated.
		All Rights Reserved.

=============================================================================
*/

@interface IntonationPoint:Object
{
	double	semitone;	/* Value of the in semitones */
	double	offsetTime;	/* Points are timed wrt a beat + this offset */
	double	slope;		/* Slope of point */
	int	ruleIndex;	/* Index of phone which is the focus of this point */
	id	eventList;	/* Current EventList */
}

- init;
- initWithEventList: aList;

- setEventList: aList;
- eventList;

- setSemitone: (double) newValue;
- (double) semitone;

- setOffsetTime: (double) newValue;
- (double) offsetTime;

- setSlope: (double) newValue;
- (double) slope;

- setRuleIndex: (int) newIndex;
- (int) ruleIndex;

- (double) absoluteTime;
- (double) beatTime;

@end
