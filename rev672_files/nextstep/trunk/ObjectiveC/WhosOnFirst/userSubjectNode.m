#import "userSubjectNode.h"
#import <string.h>
#import <stdlib.h>

char NoSubject[15] = {"No Subject."};

@implementation userSubjectNode 
{
	char *subject;
	int spoken;
}

- initWithSubject: (char *) subjectString
{
int length;

	if (!subjectString)
		subject = NoSubject;
	else
	{
		length = strlen(subjectString);
		subject = (char *) malloc (length + 1);
		strcpy(subject, subjectString);
	}

	return self;

}

- (char *) subject
{
	return subject;
}

- setSpoken: (BOOL) flag
{
	spoken = (int) flag;
	return self;
}

- (int) spoken
{
	return spoken;
}

@end
