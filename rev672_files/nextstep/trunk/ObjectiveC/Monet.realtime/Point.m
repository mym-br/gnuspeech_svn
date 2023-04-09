
#import "Point.h"
#import <stdio.h>
#import <string.h>
#import <stdlib.h>
#import "PrototypeManager.h"
#import "ProtoTemplate.h"
#import "ProtoEquation.h"
#import "EventList.h"
#import "RealTimeController.h"

@implementation Point

- init
{
	value = 0.0;
	freeTime = 0.0;
	expression = nil;
	phantom = 0;
	type = DIPHONE;
	return self;
}

- setValue: (double) newValue
{
	value = newValue;
	return self;
}

- (double) value
{
	return value;
}	

- (double) multiplyValueByFactor:(double) factor
{
	value *=factor;
	return value;
}

- (double) addValue:(double) newValue;
{
	value +=newValue;
	return value;
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

- setFreeTime: (double) newTime
{
	freeTime = newTime;
	return self;
}

- (double) freeTime
{
	return freeTime;
}

- setType: (int) newType
{
	type = newType;
	return self;
}

- (int) type
{
	return type;
}

- setPhantom: (int) phantomFlag
{
	phantom = phantomFlag;
	return self;
}

- (int) phantom
{
	return phantom;
}

- calculatePoints: (double *) ruleSymbols tempos: (double *) tempos phones: phones andCacheWith: (int) newCacheTag
	toDisplay: displayList
{
float dummy;

	if (expression)
	{
		dummy = [expression evaluate: ruleSymbols tempos: tempos phones: phones andCacheWith: (int) newCacheTag];
	}
	printf("Dummy %f\n", dummy);

	[displayList addObject:self];

	return self;
}


- (double) calculatePoints: (double *) ruleSymbols tempos: (double *) tempos phones: phones andCacheWith: (int) newCacheTag
	baseline: (double) baseline delta: (double) delta min:(double) min max:(double) max
	toEventList: eventList atIndex: (int) index;
{
double time, returnValue;

	if (expression)
		time = [expression evaluate: ruleSymbols tempos: tempos phones: phones andCacheWith: (int) newCacheTag];
	else
		time = freeTime;

//	printf("|%s| = %f tempos: %f %f %f %f \n", [[phones objectAt:0] symbol], time, tempos[0], tempos[1],tempos[2],tempos[3]);

	returnValue = baseline + ((value/100.0) * delta);

//	printf("Inserting event %d atTime %f  withValue %f\n", index, time, returnValue);

	if (returnValue<min)
		returnValue = min;
	else
	if (returnValue>max)
		returnValue = max;

	if (!phantom) [eventList insertEvent:index atTime: time withValue: returnValue];

	return returnValue;
}

- (double) getTime
{
	if (expression)
		return [expression cacheValue];
	else
		return freeTime;
}

- read:(NXTypedStream *)stream
{
int i, j;

	[super read:stream];
	NXReadTypes(stream, "ddii", &value, &freeTime, &type, &phantom);

	NXReadTypes(stream, "ii", &i,&j);
	expression = [prototypeManager findEquation: i andIndex: j];

	return self;
}

- write:(NXTypedStream *)stream
{
int i, j;

	[super write:stream];   
	NXWriteTypes(stream, "ddii", &value, &freeTime, &type, &phantom);

	[prototypeManager findList: &i andIndex: &j ofEquation: expression];
	NXWriteTypes(stream, "ii", &i, &j);

	return self;
}


@end
