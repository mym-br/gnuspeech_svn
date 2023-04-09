
#import "IntonationPoint.h"
#import "EventList.h"
#import "Phone.h"
#import <appkit/Application.h>

@implementation IntonationPoint

- init
{

	semitone = 0.0;
	offsetTime = 0.0;
	slope = 0.0;
	ruleIndex = 0;
	eventList = nil;
	return self;

}

- initWithEventList: aList
{
	[self init];
	eventList = aList;
	return self;
}

- setEventList: aList
{
	eventList = aList;
	return self;
}

- eventList
{
	return eventList;
}

- setSemitone: (double) newValue
{
	semitone = newValue;
	return self;
}

- (double) semitone
{
	return semitone;
}

- setOffsetTime: (double) newValue;
{
	offsetTime = newValue;
	return self;
}

- (double) offsetTime
{
	return offsetTime;
}

- setSlope: (double) newValue;
{
	slope = newValue;
	return self;
}

- (double) slope
{
	return slope;
}

- setRuleIndex: (int) newIndex;
{
	ruleIndex = newIndex;
	return self;
}

- (int) ruleIndex
{
	return ruleIndex;
}

- (double) absoluteTime
{
double time;

	time = [eventList getBeatAtIndex: ruleIndex];
	return time+offsetTime;
}

- (double) beatTime
{

	return [eventList getBeatAtIndex: ruleIndex];
}

@end
