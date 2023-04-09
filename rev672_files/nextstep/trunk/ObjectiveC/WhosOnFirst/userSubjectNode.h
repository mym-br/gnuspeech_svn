#import <objc/Object.h>

@interface userSubjectNode : Object
{
	char *subject;
	int spoken;
}

- initWithSubject: (char *) subjectString;
- (char *) subject;
- setSpoken: (BOOL) flag;
- (int ) spoken;

@end
