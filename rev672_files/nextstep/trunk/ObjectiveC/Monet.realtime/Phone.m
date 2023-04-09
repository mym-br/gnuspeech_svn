
#import "Phone.h"
#import "ParameterList.h"
#import <stdio.h>
#import <string.h>
#import <stdlib.h>
#import <appkit/Application.h>

extern CategoryList *mainCategoryList;

@implementation Phone

- init
{
	categoryList = [[CategoryList alloc] initCount:15];
	parameterList = [[TargetList alloc] initCount:15];
	metaParameterList = [[TargetList alloc] initCount:15];
	symbolList = [[TargetList alloc] initCount:15];

	phoneSymbol = NULL;
	comment = NULL;

	return self;
}


- free
{
	if (phoneSymbol) 
		free(phoneSymbol);

	if (comment) 
		free(comment);

	[categoryList freeNativeCategories];
	[categoryList free];

	[parameterList freeObjects];
	[parameterList free];

	[metaParameterList freeObjects];
	[metaParameterList free];

	[symbolList freeObjects];
	[symbolList free];

	[super free];

	return nil;
}

- setSymbol:(const char *) newSymbol
{
int len;
int i;
CategoryNode *tempCategory;

	if (phoneSymbol)
		free(phoneSymbol);

	len = strlen(newSymbol);
	phoneSymbol = (char *) malloc(len+1);
	strcpy(phoneSymbol, newSymbol);

	for(i = 0; i<[categoryList count]; i++)
	{
		tempCategory = [categoryList objectAt: i];
		if ([tempCategory native])
		{
			[tempCategory setSymbol:newSymbol];
			return self;
		}
	}

	return self;
}

- (const char *) symbol
{
	return (phoneSymbol);
}

- addToCategoryList: (CategoryNode *) aCategory
{
	return self;
}

- (CategoryList *) categoryList
{
	return (categoryList);
}

- (TargetList *) parameterList
{
	return (parameterList);
}

- (TargetList *) metaParameterList
{
	return metaParameterList;
}

- (TargetList *) symbolList
{
	return symbolList;
}

- read:(NXTypedStream *)stream
{
int i, j;
CategoryList *temp;
CategoryNode *temp1;
char *string;

	[super read:stream];
        NXReadTypes(stream, "**", &phoneSymbol, &comment);

	free(comment);
	comment = NULL;

	parameterList = NXReadObject(stream);
	metaParameterList = NXReadObject(stream);
	symbolList = NXReadObject(stream);

	if (categoryList)
		[categoryList free];

	NXReadType(stream,"i", &i);

	categoryList = [[CategoryList alloc] initCount:i];

	for (j = 0; j<i; j++)
	{
		NXReadType(stream, "*", &string);
		if (temp1 = [mainCategoryList findSymbol:string] )
		{
			[categoryList addObject:temp1];
		}
		else
		{
			if (strcmp(phoneSymbol, string)!=0)
			{
				[categoryList addNativeCategory:phoneSymbol];
			}
			else
				[categoryList addNativeCategory:string];
		}
		free(string);
	}


        return self;
}

- write:(NXTypedStream *)stream
{
int i;
const char *temp;

	[super write:stream];

//	printf("\tSaving %s\n", phoneSymbol);
        NXWriteTypes(stream, "**", &phoneSymbol, &comment);

//	printf("\tSaving parameter, meta, and symbolList\n", phoneSymbol);
	NXWriteObject(stream, parameterList);
	NXWriteObject(stream, metaParameterList);
	NXWriteObject(stream, symbolList);

//	printf("\tSaving categoryList\n", phoneSymbol);
	/* Here's the tricky one! */
	i = [categoryList count];

	NXWriteType(stream, "i", &i);
	for(i = 0; i<[categoryList count]; i++)
	{
		temp = [[categoryList objectAt:i] symbol];
		NXWriteType(stream, "*", &temp);
	}

        return self;
}


@end
