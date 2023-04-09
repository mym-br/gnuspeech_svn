
#import <objc/Object.h>
#import <objc/List.h>
#import "Rule.h"

/*===========================================================================

	Author: Craig-Richard Taube-Schock
		Copyright (c) 1994, Trillium Sound Research Incorporated.
		All Rights Reserved.

=============================================================================
*/
@interface RuleList:List
{
}

- findRule: categories index:(int *) index;

- read:(NXTypedStream *)stream;
- write:(NXTypedStream *)stream;

@end
