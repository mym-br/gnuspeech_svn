
#import "BooleanTerminal.h"
#import "PhoneList.h"
#import <appkit/Application.h>
#import <stdio.h>
#import <string.h>

extern id mainPhoneList;
extern id mainCategoryList;

@implementation BooleanTerminal

- init
{
	category = nil;
	matchAll = 0;
	return self;
}

- setCategory:newCategory
{
	category = newCategory;
	return self;
}
- category
{
	return category;
}

- setMatchAll:(int) value
{
	matchAll = value;
	return self;
}
- (int) matchAll
{
	return matchAll;
}

- (int) evaluate: (CategoryList *) categories
{
char string[256];

	if ([categories indexOf: category] == NX_NOT_IN_LIST)
	{
		if (matchAll)
		{
			sprintf(string,"%s", [category symbol]);
			if ([categories findSymbol:string])
				return 1;

			sprintf(string,"%s'", [category symbol]);
			if ([categories findSymbol:string])
				return 1;
		}
		return 0;
	}
	else
	{
		return 1;
	}
}

- optimize
{
	return self;
}

- optimizeSubExpressions
{
	return self;
}

- (int) maxExpressionLevels
{
	return 1;
}
- expressionString:(char *) string
{
	if (category == nil)
		return NULL;

//	printf("%s", [category symbol]);
	strcat(string, [category symbol]);
	if (matchAll)
		strcat(string, "*");

	return self;
}

- (BOOL) isCategoryUsed: aCategory
{
	if (category == aCategory)
		return YES;
	return NO;
}

- read:(NXTypedStream *)stream
{
char *string;
CategoryList *temp;
PhoneList *phoneList;
CategoryNode *temp1;

	[super read:stream];
	NXReadType(stream, "i", &matchAll);

	NXReadType(stream, "*", &string);

	temp1 = [mainCategoryList findSymbol:string];
	if (!temp1)
	{
		temp1 = [[[mainPhoneList findPhone:string] categoryList] findSymbol:string];
		category = temp1;
	}
	else
	{
		category = temp1;
	}

	free(string);
	return self;
}

- write:(NXTypedStream *)stream
{
const char *temp;

	[super write:stream];

	NXWriteType(stream, "i", &matchAll);

	temp = [category symbol];
	NXWriteType(stream, "*", &temp);


	return self;
}

@end
