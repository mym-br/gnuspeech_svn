
#import <objc/Object.h>

/*===========================================================================

	Author: Craig-Richard Taube-Schock
		Copyright (c) 1994, Trillium Sound Research Incorporated.
		All Rights Reserved.

=============================================================================
*/

@interface Target:Object
{
	int is_default;
	double value;
}

- init;
- (double) value;
- (int)isDefault;

- read:(NXTypedStream *)stream;
- write:(NXTypedStream *)stream;

@end
