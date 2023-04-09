
#import <objc/Object.h>
#import <objc/List.h>
#import "Parameter.h"

@interface ParameterList:List
{
}

- (Parameter *) findParameter: (const char *) symbol;
- addParameter: (const char *) newSymbol min:(float) minValue max:(float) maxValue def:(float) defaultValue;

@end
