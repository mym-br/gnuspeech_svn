
#import "SlopeRatio.h"
#import "Point.h"
#import "ProtoEquation.h"

/*===========================================================================

	Author: Craig-Richard Taube-Schock
		Copyright (c) 1994, Trillium Sound Research Incorporated.
		All Rights Reserved.

=============================================================================
*/

@implementation SlopeRatio

- init
{
	points = [[List alloc] initCount:4];
	slopes = [[List alloc] initCount:4];
	return self;
}

- setPoints: newList
{
int i;
Slope *tempSlope;

	if (points)
		[points free];
	points = newList;

	[self updateSlopes];	

	return self;
}

- points
{
	return points;
}

- setSlopes: newList
{
	if (slopes)
		[slopes free];
	slopes = newList;
	return self;
}

- updateSlopes
{
int i;
Slope *tempSlope;

	if ([slopes count]>([points count]-1))
	{
		while([slopes count]>([points count]-1))
		{
			[[slopes removeLastObject] free];
		}
		return self;
	}

	if ([slopes count]<([points count]-1))
	{
		while([slopes count]<([points count]-1))
		{
			tempSlope = [[Slope alloc] init];
			[tempSlope setSlope:1.0];
			[slopes addObject:tempSlope];
		}
		return self;
	}

	return self;
}

- slopes
{
	return slopes;
}

- free
{
	[points free];
	return self;
}

- (double) startTime
{
	return [[[points objectAt:0] expression] cacheValue];
}

- (double) endTime
{
	return [[[points lastObject] expression] cacheValue];
}

- calculatePoints: (double *) ruleSymbols tempos: (double *) tempos phones: phones andCacheWith: (int) newCacheTag 
        toDisplay: displayList ;
{
int i, numSlopes;
double temp = 0.0, temp1 = 0.0, intervalTime = 0.0, sum = 0.0, factor = 0.0;
double dummy, baseTime = 0.0, endTime = 0.0, totalTime = 0.0, delta = 0.0;
double startValue;
Point *currentPoint;

	/* Calculate the times for all points */
	for (i = 0; i< [points count]; i++)
	{
		currentPoint = [points objectAt:i];
		dummy = [[currentPoint expression] evaluate: ruleSymbols tempos: tempos phones: phones 
				andCacheWith: newCacheTag];

		[displayList addObject:currentPoint];
	}

	baseTime = [[points objectAt: 0] getTime];
	endTime = [[points lastObject] getTime];

	startValue = [[points objectAt:0] value];
	delta = [[points lastObject] value] - startValue;

	temp = [self totalSlopeUnits];
	totalTime = endTime-baseTime;

	numSlopes = [slopes count];
	for (i = 1; i< numSlopes+1; i++)
	{
		temp1 = [[slopes objectAt:i-1] slope] / temp;	/* Calculate normal slope */

		/* Calculate time interval */
		intervalTime = [[points objectAt:i] getTime] - [[points objectAt:i-1] getTime];

		/* Apply interval percentage to slope */
		temp1 = temp1*(intervalTime/totalTime);

		/* Multiply by delta and add to last point */
		temp1 = (temp1*delta);
		sum+=temp1;

		if (i<numSlopes)
			[[points objectAt: i] setValue: temp1];
	}
	factor = delta/sum;

	temp = startValue;
	for(i = 1; i< [points count]-1; i++)
	{
		temp1 = [[points objectAt: i] multiplyValueByFactor:factor];
		temp = [[points objectAt: i] addValue:temp];
	}

	return self;
}

- (double) calculatePoints: (double *) ruleSymbols tempos: (double *) tempos phones: phones andCacheWith: (int) newCacheTag
	baseline: (double) baseline delta: (double) parameterDelta min: (double) min max:(double) max
	toEventList: eventList atIndex: (int) index
{
double returnValue = 0.0;
int i, numSlopes;
double temp = 0.0, temp1 = 0.0, intervalTime = 0.0, sum = 0.0, factor = 0.0;
double dummy, baseTime = 0.0, endTime = 0.0, totalTime = 0.0, delta = 0.0;
double startValue;
Point *currentPoint;

	/* Calculate the times for all points */
	for (i = 0; i< [points count]; i++)
	{
		currentPoint = [points objectAt:i];
		dummy = [[currentPoint expression] evaluate: ruleSymbols tempos: tempos phones: phones 
				andCacheWith: newCacheTag];
	}

	baseTime = [[points objectAt: 0] getTime];
	endTime = [[points lastObject] getTime];

	startValue = [[points objectAt:0] value];
	delta = [[points lastObject] value] - startValue;

	temp = [self totalSlopeUnits];
	totalTime = endTime-baseTime;

	numSlopes = [slopes count];
	for (i = 1; i< numSlopes+1; i++)
	{
		temp1 = [[slopes objectAt:i-1] slope] / temp;	/* Calculate normal slope */

		/* Calculate time interval */
		intervalTime = [[points objectAt:i] getTime] - [[points objectAt:i-1] getTime];

		/* Apply interval percentage to slope */
		temp1 = temp1*(intervalTime/totalTime);

		/* Multiply by delta and add to last point */
		temp1 = (temp1*delta);
		sum+=temp1;

		if (i<numSlopes)
			[[points objectAt: i] setValue: temp1];
	}
	factor = delta/sum;
	temp = startValue;

	for(i = 1; i< [points count]-1; i++)
	{
		temp1 = [[points objectAt: i] multiplyValueByFactor:factor];
		temp = [[points objectAt: i] addValue:temp];
	}

	for(i = 0; i<[points count]; i++)
	{
		returnValue = [[points objectAt: i] calculatePoints: ruleSymbols tempos: tempos phones: phones 
					andCacheWith: newCacheTag baseline: baseline delta: parameterDelta
					min: min max:max toEventList: eventList atIndex: index];
	}

	return returnValue;
}

- (double)totalSlopeUnits
{
int i;
double temp = 0.0;

	for (i = 0; i<[slopes count]; i++)
		temp+=[[slopes objectAt:i] slope];

	return temp;
}

- displaySlopesInList: (List *) displaySlopes
{
int i;
double tempTime;

	printf("DisplaySlopesInList: Count = %d\n", [slopes count]);
	for (i = 0; i< [slopes count]; i++)
	{
		tempTime = ([[points objectAt:i] getTime] + [[points objectAt:i+1] getTime]) /2.0;
		[[slopes objectAt:i] setDisplayTime: tempTime];
		printf("TempTime = %f\n", tempTime);
		[displaySlopes addObject: [slopes objectAt:i]];
	}

	return self;
}

- read:(NXTypedStream *)stream
{
	[super read:stream];

	[points free];
	[slopes free];

	points = NXReadObject(stream);
	slopes = NXReadObject(stream);

	return self;
}

- write:(NXTypedStream *)stream
{
	[super write:stream];
	NXWriteObject(stream, points);
	NXWriteObject(stream, slopes);
	return self;
}

@end
