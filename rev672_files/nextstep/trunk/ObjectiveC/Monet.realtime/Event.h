
#import <objc/Object.h>

/*===========================================================================

	Author: Craig-Richard Taube-Schock
		Copyright (c) 1994, Trillium Sound Research Incorporated.
		All Rights Reserved.

=============================================================================
*/

#define NaN 1.0/0.0

@interface Event:Object
{
	int time;
	int flag;
	double events[36];

}

- init;
- setTime: (int) newTime;
- (int) time;
- setFlag:(int) newFlag;
- (int) flag;
- setValue: (double) newValue ofIndex: (int) index;
- (double) getValueAtIndex:(int) index;

@end
