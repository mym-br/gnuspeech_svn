
#import "CategoryList.h"

/*===========================================================================

	This Class currently adds no functionality to the List class.
	However, it is planned that this object will provide sorting functions
	to the CategoryNode class.

===========================================================================*/

@implementation CategoryList

-findSymbol:(const char *) searchSymbol
{
int i;
const char *temp;

//	printf("CategoryList searching for: %s\n", searchSymbol);
	for (i = 0; i<numElements; i++)
	{
		temp = [ dataPtr[i] symbol];
		if (strcmp(temp, searchSymbol)==0)
		{
//			printf("Found: %s\n", searchSymbol);
			return dataPtr[i];
		}
	}
//	printf("Could not find: %s\n", searchSymbol);
	return nil;
}

- addCategory:(const char *) newCategory
{
CategoryNode *tempCategory;

	tempCategory = [[CategoryNode alloc] initWithSymbol: newCategory];
	[self addObject: tempCategory];

	return tempCategory;
}

- addNativeCategory:(const char *) newCategory
{
CategoryNode *tempCategory;

	tempCategory = [[CategoryNode alloc] initWithSymbol: newCategory];
	[tempCategory setNative: 1];
	[self addObject: tempCategory];

	return self;
}

- freeNativeCategories
{

	[self makeObjectsPerform: (SEL)(@selector(freeIfNative))];
	return self;
}

/* BrowserManager List delegate Methods */
- addNewValue:(const char *) newValue
{
	[self addCategory: newValue];
	return self;
}

- findByName:(const char *) name
{
	return [self findSymbol:name];
}

- changeSymbolOf:temp to:(const char *) name
{
	[temp setSymbol:name];
	return self;
}

#define SYMBOL_LENGTH_MAX 12
- readDegasFileFormat:(NXStream *) fp
{
int i, count;

CategoryNode *currentNode;
char tempString[SYMBOL_LENGTH_MAX+1];

	/* Load in the count */
	NXRead(fp, &count, sizeof(int));
//	fread(&count,sizeof(int),1,fp1);

	for (i = 0; i < count; i++)
	{
		NXRead(fp, tempString, SYMBOL_LENGTH_MAX+1);

//		fread(tempString,SYMBOL_LENGTH_MAX+1,1,fp1);

		currentNode = [[CategoryNode alloc] initWithSymbol: tempString];
		[self addObject:currentNode];
	}

	if (![self findSymbol: "phone"])
		[self addCategory:"phone"];



	return self;
}

- printDataTo: (FILE *) fp
{
int i;

	fprintf(fp, "Categories\n");
	for (i = 0; i<numElements; i++)
	{
		fprintf(fp, "%s\n", [dataPtr[i] symbol]);
		if ([dataPtr[i] comment])
			fprintf(fp,"%s\n", [dataPtr[i] comment]);
		fprintf(fp, "\n");
	}
	fprintf(fp, "\n");
	return self;
}

- read:(NXTypedStream *)stream
{
	[super read:stream];
	return self;
}

- write:(NXTypedStream *)stream
{
	[super write:stream];
	return self;
}

@end
