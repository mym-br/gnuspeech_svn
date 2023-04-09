
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

- initWithValue:(float) newValue isDefault:(int) isDefault
{
	[self setValue: newValue];
	[self setDefault: isDefault];
	return self;
}

- setValue:(float) newValue
{
	value = newValue;
	return self;
}

- (float) value
{
	return(value);
}

- setDefault:(int) isDefault
{
	is_default = isDefault;
	return self;
}

- (int)isDefault
{
	return (is_default);
}

- setValue:(float) newValue isDefault:(int) isDefault
{
	[self setValue: newValue];
	[self setDefault: isDefault];
	return self;
}

@end
