
#import <objc/Object.h>

@interface CategoryNode:Object
{
	char *symbol;
	int native;
}

- init;
- initWithSymbol:(const char *) newSymbol;

- setSymbol:(const char *) newSymbol;
- (const char *) symbol;

- setNative:(int) isNative;
- (int) native;

- free;

@end
