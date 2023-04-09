
#import <objc/Object.h>
#import <objc/List.h>
#import "TargetList.h"
#import "CategoryList.h"

@interface Parameter:Object
{
	char 	*parameterSymbol;
	float	minimum;
	float	maximum;
	float	defaultValue;

}

- init;
- initWithSymbol:(const char *) newSymbol;
- free;

- setSymbol:(char *) newSymbol;
- (const char *) symbol;

- setMinimum: (float) newMinimum;
- (float) minimum;

- setMaximum: (float) newMaximum;
- (float) maximum;

- setDefaultValue: (float) newDefault;
- (float) defaultValue;

@end
