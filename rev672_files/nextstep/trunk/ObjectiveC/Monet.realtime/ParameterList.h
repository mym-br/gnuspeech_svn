
#import <objc/Object.h>
#import <objc/List.h>
#import "Parameter.h"
#import <stdio.h>

/*===========================================================================

	Author: Craig-Richard Taube-Schock
		Copyright (c) 1994, Trillium Sound Research Incorporated.
		All Rights Reserved.

=============================================================================
*/

@interface ParameterList:List
{
}

- (Parameter *) findParameter: (const char *) symbol;
- (int) findParameterIndex: (const char *) symbol;
- (double) defaultValueFromIndex:(int) index;
- (double) minValueFromIndex:(int) index;
- (double) maxValueFromIndex:(int) index;


@end
