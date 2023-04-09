
#import <objc/Object.h>
#import <objc/List.h>

/*===========================================================================

	Author: Craig-Richard Taube-Schock
		Copyright (c) 1994, Trillium Sound Research Incorporated.
		All Rights Reserved.

=============================================================================
*/

@interface NamedList:List
{
	char *name;
	char *comment;
}

- init;
- initCount:(unsigned) numSlots;

- setComment: (const char *) newComment;
- (const char *) comment;

- setName: (const char *) newName;
- (const char *) name;

- read:(NXTypedStream *)stream;
- write:(NXTypedStream *)stream;

@end
