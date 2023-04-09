
#import "ProtoTemplate.h"
#import "PrototypeManager.h"
#import "Point.h"
#import "SlopeRatio.h"
#import <stdio.h>
#import <string.h>
#import <stdlib.h>
#import <appkit/Application.h>
#import <appkit/Panel.h>

@implementation ProtoTemplate

- init
{
Point *tempPoint;

	name = NULL;
	comment = NULL;
	type = DIPHONE;
	points = [[List alloc] initCount:2];

	tempPoint = [[Point alloc] init];
	[tempPoint setType: DIPHONE];
	[tempPoint setFreeTime:0.0];
	[tempPoint setValue: 0.0];
	[points addObject:tempPoint];

	return self;
}

- initWithName:(const char *) newName
{
	[self init];
	[self setName: newName];
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

- setPoints: newList
{
	points = newList;
	return self;
}

- points
{
	return points;
}

- setType:(int) newType
{
	type = newType;
	return self;
}

- (int) type
{
	return type;
}

- free
{
	if (name) 
		free(name);

	if (comment) 
		free(comment);

	[points freeObjects];
	[points free];

	[super free];

	return nil;
}

- (BOOL) isEquationUsed: anEquation
{
int i, j;
id temp;
	for(i = 0; i<[points count]; i++)
	{
		temp = [points objectAt: i];
		if ([temp isKindOfClassNamed:"SlopeRatio"])
		{
			temp = [temp points];
			for (j = 0; j<[temp count]; j++)
				if (anEquation == [[temp objectAt:j] expression])
					return YES;
		}
		else
			if (anEquation == [[points objectAt:i] expression])
				return YES;
	}
	return NO;
}

- read:(NXTypedStream *)stream
{
id tempPoint;

	[super read:stream];

	NXReadTypes(stream, "**i", &name, &comment, &type);
	points = NXReadObject(stream);

	return self;
}

- write:(NXTypedStream *)stream
{
	[super write:stream];

	NXWriteTypes(stream, "**i", &name, &comment, &type);
	NXWriteObject(stream, points);

	return self;
}

@end
