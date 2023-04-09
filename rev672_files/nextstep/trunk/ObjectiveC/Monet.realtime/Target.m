
#import "Target.h"
#import <stdio.h>
#import <string.h>
#import <stdlib.h>

@implementation Target

- init
{
	is_default = 1;
	value = 0.0;
	return self;
}

- (double) value
{
	return(value);
}

- (int)isDefault
{
	return (is_default);
}

- read:(NXTypedStream *)stream
{
	[super read:stream];
	NXReadTypes(stream, "id", &is_default, &value);
	return self;
}

- write:(NXTypedStream *)stream
{
	[super write:stream];	
	NXWriteTypes(stream,"id", &is_default, &value);
	return self;
}

@end
