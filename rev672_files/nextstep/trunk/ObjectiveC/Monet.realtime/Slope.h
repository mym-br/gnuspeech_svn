
#import <objc/Object.h>
#import <appkit/graphics.h>

/*===========================================================================

	Author: Craig-Richard Taube-Schock
		Copyright (c) 1994, Trillium Sound Research Incorporated.
		All Rights Reserved.

=============================================================================
*/

@interface Slope:Object
{
	double slope;
	double displayTime;
}

- init;

- (double) slope;

- (double) displayTime;

- read:(NXTypedStream *)stream;
- write:(NXTypedStream *)stream;

@end
