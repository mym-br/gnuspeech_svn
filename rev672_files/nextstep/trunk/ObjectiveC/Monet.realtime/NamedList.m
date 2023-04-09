
#import "NamedList.h"
#import <stdio.h>
#import <stdlib.h>

/*===========================================================================


===========================================================================*/

@implementation NamedList

- initCount: (unsigned) numSlots
{
	[super initCount:numSlots];
	comment = NULL;
	name = NULL;

	return self;
}

- init
{
	[super init];
	comment = NULL;
	name = NULL;

	return self;

}

- setName:(const char *) newName
{
int len;
	if (name)
		free(name);

	len = strlen(newName);
	name = (char *) malloc(len+1);
	strcpy(name, newName);

	return self;
}

- (const char *) name
{
	return( (const char *) name);
}

- setComment:(const char *) newComment
{
int len;

	if (comment)
		free(comment);

	len = strlen(newComment);
	comment = (char *) malloc(len+1);
	strcpy(comment, newComment);

	return self;
}

- (const char *) comment
{
	return comment;
}

- read:(NXTypedStream *)stream
{
	[super read:stream];

	NXReadTypes(stream, "**", &name, &comment);

	return self;
}

- write:(NXTypedStream *)stream
{
	[super write:stream];

	NXWriteTypes(stream, "**", &name, &comment);

	return self;
}

@end
