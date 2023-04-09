
#import "Slope.h"

/*===========================================================================

	Author: Craig-Richard Taube-Schock
		Copyright (c) 1994, Trillium Sound Research Incorporated.
		All Rights Reserved.

=============================================================================
*/

@implementation Slope

- init
{
	slope = 0.0;
	return self;
}

- (double) slope
{
	return slope;
}


- (double) displayTime
{
	return displayTime;
}

- read:(NXTypedStream *)stream
{
	[super read:stream];
	NXReadType(stream, "d", &slope);	
	return self;
}

- write:(NXTypedStream *)stream
{
	[super write:stream];
	NXWriteType(stream,"d", &slope);
	return self;
}

@end
