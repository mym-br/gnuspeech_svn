#import <objc/Object.h>
#import <objc/List.h>

@interface userMailNode : Object
{
	char 	*name;
	id	subjectList;
}

- initWithName: (char *) nameString;
- (char *) name;

- subjectList;
- unspokenSubjectList;

- setAllSpoken;

- addSubjectString: (char *) string;

- (int) totalNumber;
- (int) totalUnspoken;


@end
