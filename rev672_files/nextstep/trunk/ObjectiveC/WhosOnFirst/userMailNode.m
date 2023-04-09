#import "userMailNode.h"
#import "userSubjectNode.h"
#import <string.h>
#import <stdlib.h>

@implementation userMailNode

- initWithName: (char *) nameString
{
int length;

	if (!nameString)
		return nil;
	else
	{
		subjectList = [[List alloc] initCount:10];

		length = strlen(nameString);
		name = (char *) malloc (length + 1);
		strcpy(subject, nameString);
	}
	return self;
}

- (char *) name
{
	return name;
}

- subjectList
{
	return subjectList;
}

- unspokenSubjectList
{
id temp;
int i;

	temp = [[List alloc] initCount: [self totalUnspoken]];
	for(i = 0; i< [subjectList count] ; i++)
		if (![[subjectList objectAt:i] spoken])
			[temp addObject: [subjectList objectAt:i]];

	return temp;
}

- setAllSpoken
{
int i;
	for(i = 0; i< [subjectList count] ; i++)
		if (![[subjectList objectAt:i] spoken])
			[[subjectList objectAt:i] setSpoken:TRUE];
	return self;
}

- addSubjectString: (char *) string
{
id temp;

	temp = [[userSubjectNode alloc] initWithSubject: string];
	if (temp)
		[subjectList addObject:temp];
	return self;
}

- (int) totalNumber
{
	return [subjectList count];
}

- (int) totalUnspoken
{
int i, j = 0;

	for(i = 0; i<[subjectList count] ; i++)
		if (![[subjectList objectAt:i] spoken])
			j++;

	return j;
}


@end
