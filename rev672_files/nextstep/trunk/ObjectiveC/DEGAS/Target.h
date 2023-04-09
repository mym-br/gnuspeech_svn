
#import <objc/Object.h>

@interface Target:Object
{
	int is_default;
	float value;
}

- init;
- initWithValue:(float) newValue isDefault:(int) isDefault;
- setValue:(float) newValue;
- (float) value;
- setDefault:(int) isDefault;
- (int)isDefault;
- setValue:(float) newValue isDefault:(int) isDefault;

@end
