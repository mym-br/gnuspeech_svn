
#import <objc/Object.h>

@interface CategoryNode:Object
{
	char *symbol;
	char *comment;
	int native;
}

- init;
- initWithSymbol:(const char *) newSymbol;

- setSymbol:(const char *) newSymbol;
- (const char *) symbol;
- setComment:(const char *) newComment;
- (const char *) comment;

- setNative:(int) isNative;
- (int) native;

- free;
- freeIfNative;

- read:(NXTypedStream *)stream;
- write:(NXTypedStream *)stream;
@end
