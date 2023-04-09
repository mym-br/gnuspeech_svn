
#import <objc/Object.h>

/*===========================================================================

	Author: Craig-Richard Taube-Schock
		Copyright (c) 1994, Trillium Sound Research Incorporated.
		All Rights Reserved.

=============================================================================
*/

@interface Symbol:Object
{
	char *symbol;
	char *comment;
	double minimum;
	double maximum;
	double defaultValue;
}

- init;

- (const char *) symbol;
- (double) minimum;
- (double) maximum;
- (double) defaultValue;

- free;

- read:(NXTypedStream *)stream;
- write:(NXTypedStream *)stream;

@end
