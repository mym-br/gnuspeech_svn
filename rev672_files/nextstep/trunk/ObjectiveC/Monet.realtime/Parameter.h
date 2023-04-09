
#import <objc/Object.h>
#import <objc/List.h>
#import "TargetList.h"
#import "CategoryList.h"

/*===========================================================================

	Author: Craig-Richard Taube-Schock
		Copyright (c) 1994, Trillium Sound Research Incorporated.
		All Rights Reserved.

=============================================================================
*/

@interface Parameter:Object
{
	char 	*parameterSymbol;
	char	*comment;
	double	minimum;
	double	maximum;
	double	defaultValue;

}

- init;
- initWithSymbol:(const char *) newSymbol;
- free;

- setSymbol:(const char *) newSymbol;
- (const char *) symbol;
- setComment:(const char *) newComment;
- (const char *) comment;

- setMinimum: (double) newMinimum;
- (double) minimum;

- setMaximum: (double) newMaximum;
- (double) maximum;

- setDefaultValue: (double) newDefault;
- (double) defaultValue;

- read:(NXTypedStream *)stream;
- write:(NXTypedStream *)stream;

@end
