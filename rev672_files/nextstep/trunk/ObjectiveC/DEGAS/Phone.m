
#import "Phone.h"
#import <stdio.h>
#import <string.h>
#import <stdlib.h>

@implementation Phone

- init
{
	categoryList = [[CategoryList alloc] initCount:15];
	targetList = [[TargetList alloc] initCount:15];

	phoneSymbol = NULL;
	duration = 0;

	type = 0;
	fixed = 0;
	prop = 0.0;
	
	return self;
}

- initWithSymbol:(const char *) newSymbol
{
	[self init];
	[self setSymbol:newSymbol];
	return self;
}

- free
{
	if (phoneSymbol) 
		free(phoneSymbol);
	[categoryList freeNativeCategories];
	[categoryList free];
	[targetList free];
	[super free];

	return nil;
}

- setSymbol:(char *) newSymbol
{
int len;

	if (phoneSymbol)
		free(phoneSymbol);

	len = strlen(newSymbol);
	phoneSymbol = (char *) malloc(len+1);
	strcpy(phoneSymbol, newSymbol);

	return self;
}

- (const char *) symbol
{
	return (phoneSymbol);
}

- setDuration: (int) newDuration
{
	duration = newDuration;
	return self;
}

- (int) duration
{
	return duration;
}

- setType:(int) newType
{
	type = newType;
	return self;
}

- (int) type
{
	return type;
}

- setFixed:(int) newFixed;
{
	fixed = newFixed;
	return self;
}

- (int) fixed;
{
	return fixed;
}

- setProp:(float) newProp;
{
	prop = newProp;
	return self;
}

- (float) prop;
{
	return prop;
}

- addToCategoryList: (CategoryNode *) aCategory
{
	return self;
}

- (CategoryList *) categoryList
{
	return (categoryList);
}

- (TargetList *) targetList
{
	return (targetList);
}


@end
