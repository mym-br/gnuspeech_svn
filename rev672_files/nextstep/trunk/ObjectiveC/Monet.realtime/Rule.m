
#import "Rule.h"
#import <stdio.h>
#import <string.h>
#import <stdlib.h>
#import <appkit/Application.h>
#import "PrototypeManager.h"
#import "ProtoEquation.h"
#import "ParameterList.h"

@implementation Rule

extern ParameterList *mainParameterList;
extern ParameterList *mainMetaParameterList;

extern PrototypeManager *prototypeManager;

- init
{
id tempList;
int i;
	/* Alloc lists to point to prototype transition specifiers */
	parameterProfiles = [[List alloc] initCount:[mainParameterList count]];

	metaParameterProfiles = [[List alloc] initCount:[mainMetaParameterList count]];

	/* Set up list for Expression symbols */
	expressionSymbols = [[List alloc] initCount: 5];

	/* Zero out expressions and special Profiles */
	bzero(expressions, sizeof(BooleanExpression *) * 4); 
	bzero(specialProfiles, sizeof(id) * 16);

	return self;
}

- free
{
int i;
	for(i = 0 ; i<4; i++)
		if (expressions[i])
			[expressions[i] free];

	[super free];
	return nil;
}

- getExpressionNumber:(int) index
{
	if ((index>3) || (index<0))
		return nil;
	return (expressions[index]);
}

- (int) numberExpressions
{
int i;

	for (i = 0; i<4; i++)
		if (expressions[i] == nil)
			return (i);
	return i;
}

-(int)matchRule: (List *) categories
{
int i;

	for (i = 0; i< [self numberExpressions]; i++)
	{
		if (![expressions[i] evaluate:[categories objectAt:i]])
			return 0;
	}

	return 1;
}

- getExpressionSymbol:(int) index
{
	return [expressionSymbols objectAt:index];
}

- evaluateExpressionSymbols:(double *) buffer tempos: (double *) tempos phones: phones withCache: (int) cache;
{
int i;
	buffer[0] = [(ProtoEquation *) [expressionSymbols objectAt:0] evaluate: buffer tempos: tempos
		 phones: phones andCacheWith: cache];
	buffer[2] = [(ProtoEquation *) [expressionSymbols objectAt:2] evaluate: buffer tempos: tempos
		phones: phones andCacheWith: cache];
	buffer[3] = [(ProtoEquation *) [expressionSymbols objectAt:3] evaluate: buffer tempos: tempos
		phones: phones andCacheWith: cache];
	buffer[4] = [(ProtoEquation *) [expressionSymbols objectAt:4] evaluate: buffer tempos: tempos
		phones: phones andCacheWith: cache];
	buffer[1] = [(ProtoEquation *) [expressionSymbols objectAt:1] evaluate: buffer tempos: tempos
		phones: phones andCacheWith: cache];

	return self;
}

- parameterList
{
	return parameterProfiles;
}

- metaParameterList
{
	return metaParameterProfiles;
}

- symbols
{
	return expressionSymbols;
}

- getSpecialProfile:(int) index
{
	if ((index>15) || (index<0))
		return nil;
	else
		return specialProfiles[index];
}

- setSpecialProfile:(int) index to:special
{
	if ((index>15) || (index<0))
		return self;

	specialProfiles[index] = special;

	return self;
}

- read:(NXTypedStream *)stream
{
int i, j, k;
int parms, metaParms, symbols;
id tempParameter, tempList;

	[super read:stream];

	parameterProfiles = [[List alloc] initCount:[mainParameterList count]];

	metaParameterProfiles = [[List alloc] initCount:[mainMetaParameterList count]];

	expressionSymbols = [[List alloc] initCount: 5];

	NXReadTypes(stream,"i*", &i, &comment);
	bzero(expressions, sizeof(BooleanExpression *) * 4); 
	for (j = 0; j<i; j++)
	{
		expressions[j] = NXReadObject(stream);
	}

	[expressionSymbols empty];
	[parameterProfiles empty];
	[metaParameterProfiles empty];
	bzero(specialProfiles, sizeof(id) * 16);

	NXReadTypes(stream, "iii", &symbols, &parms, &metaParms);

	for (i = 0; i<symbols; i++)
	{
		NXReadTypes(stream, "ii", &j, &k);
		tempParameter = [prototypeManager findEquation: j andIndex: k];
		[expressionSymbols addObject: tempParameter];
	}

	for (i = 0; i<parms; i++)
	{
		NXReadTypes(stream, "ii", &j, &k);
		tempParameter = [prototypeManager findTransition: j andIndex: k];
		[parameterProfiles addObject: tempParameter];
	}

	for (i = 0; i<metaParms; i++)
	{
		NXReadTypes(stream, "ii", &j, &k);
		[metaParameterProfiles addObject: [prototypeManager findTransition: j andIndex: k]];
	}

	for(i = 0; i< 16; i++)
	{
		NXReadTypes(stream, "ii", &j, &k);
		if (i==(-1))
		{
			specialProfiles[i] = nil;
		}
		else
		{
			specialProfiles[i] = [prototypeManager findSpecial: j andIndex: k];
		}
	}
	return self;
}

- write:(NXTypedStream *)stream
{
int i, j, k, dummy;
int parms, metaParms, symbols;

	[super write:stream];

	i = [self numberExpressions];
	NXWriteTypes(stream, "i*", &i, &comment);

	for(j = 0; j<i; j++)
	{
		NXWriteObject(stream, expressions[j]);
	}

	symbols = [expressionSymbols count];
	parms = [parameterProfiles count];
	metaParms = [metaParameterProfiles count];
	NXWriteTypes(stream, "iii", &symbols, &parms, &metaParms);

	for (i = 0; i<symbols; i++)
	{
		[prototypeManager findList: &j andIndex: &k ofEquation: [expressionSymbols objectAt: i]];
		NXWriteTypes(stream, "ii", &j, &k);
	}

	for (i = 0; i<parms; i++)
	{
		[prototypeManager findList: &j andIndex: &k ofTransition: [parameterProfiles objectAt: i]];
		NXWriteTypes(stream, "ii", &j, &k);
	}

	for (i = 0; i<metaParms; i++)
	{
		[prototypeManager findList: &j andIndex: &k ofTransition: [metaParameterProfiles objectAt: i]];
		NXWriteTypes(stream, "ii", &j, &k);
	}

	dummy = (-1);

	for(i = 0; i< 16; i++)
	{
		if (specialProfiles[i]!=nil)
		{
			[prototypeManager findList:&j andIndex: &k ofSpecial: specialProfiles[i]];
			NXWriteTypes(stream, "ii", &j, &k);
		}
		else
		{
			NXWriteTypes(stream, "ii", &dummy, &dummy);
		}
	}

	return self;
}

@end
