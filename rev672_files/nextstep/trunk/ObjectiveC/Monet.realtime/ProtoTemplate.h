
#import <objc/Object.h>
#import <objc/List.h>

/*===========================================================================

	Author: Craig-Richard Taube-Schock
		Copyright (c) 1994, Trillium Sound Research Incorporated.
		All Rights Reserved.

=============================================================================
*/

#define DIPHONE 2
#define TRIPHONE 3
#define TETRAPHONE 4

@interface ProtoTemplate:Object
{
	char 	*name;
	char 	*comment;
	int	type;
	List	*points;
}

- init;
- initWithName:(const char *) newName;

- setName:(const char *) newName;
- (const char *) name;

- setComment:(const char *) newComment;
- (const char *) comment;

- setPoints: newList;
- points;

- setType:(int) type;
- (int) type;

- free;

- (BOOL) isEquationUsed: anEquation;

- read:(NXTypedStream *)stream;
- write:(NXTypedStream *)stream;

@end
