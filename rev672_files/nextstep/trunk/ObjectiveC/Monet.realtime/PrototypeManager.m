
#import "PrototypeManager.h"
#import "ProtoEquation.h"
#import "ProtoTemplate.h"
#import <appkit/Pasteboard.h>
#import <streams/streams.h>

@implementation PrototypeManager

- init
{
NamedList *tempList;
ProtoEquation *tempEquation;

	/* Set up Prototype equations major list */
	protoEquations = [[List alloc] initCount:10];

	/* Set up Protytype transitions major list */
	protoTemplates = [[List alloc] initCount:10];

	/* Set up Prototype Special Transitions major list */
	protoSpecial = [[List alloc] initCount:10];

	return self;
}

- appDidInit:sender
{
	return self;
}

- equationList
{
	return protoEquations;
}

- transitionList
{
	return protoTemplates;
}

- specialList
{
	return protoSpecial;
}

- findEquationList: (const char *) list named: (const char *) name
{
id tempList;
int i, j;

	for (i = 0 ; i < [protoEquations count]; i++)
	{
		if (!strcmp(list, [[protoEquations objectAt:i] name]))
		{
			tempList = [protoEquations objectAt:i];
			for (j = 0; j < [tempList count]; j++)
			{
				if (!strcmp(name, [[tempList objectAt: j] name]))
					return [tempList objectAt: j];
			}
		}

	}
	return nil;
}

- findList: (int *) listIndex andIndex: (int *) index ofEquation: equation
{
int i, temp;

	for (i = 0 ; i < [protoEquations count]; i++)
	{
		temp = [[protoEquations objectAt:i] indexOf:equation];
		if (temp != NX_NOT_IN_LIST)
		{
			*listIndex = i;
			*index = temp;
			return self;
		}

	}
	*listIndex = (-1);
	return self;
}

- findEquation: (int) listIndex andIndex: (int) index
{
	return [[protoEquations objectAt: listIndex] objectAt: index];
}

- findTransitionList: (const char *) list named: (const char *) name
{
id tempList;
int i, j;

	for (i = 0 ; i < [protoTemplates count]; i++)
	{
		if (!strcmp(list, [[protoTemplates objectAt:i] name]))
		{
			tempList = [protoTemplates objectAt:i];
			for (j = 0; j < [tempList count]; j++)
			{
				if (!strcmp(name, [[tempList objectAt: j] name]))
					return [tempList objectAt: j];
			}
		}

	}
	return nil;
}

- findList: (int *) listIndex andIndex: (int *) index ofTransition: transition
{
int i, temp;

	for (i = 0 ; i < [protoTemplates count]; i++)
	{
		temp = [[protoTemplates objectAt:i] indexOf:transition];
		if (temp != NX_NOT_IN_LIST)
		{
			*listIndex = i;
			*index = temp;
			return self;
		}

	}
	*listIndex = (-1);
	return self;
}

- findTransition: (int) listIndex andIndex: (int) index
{
	return [[protoTemplates objectAt: listIndex] objectAt: index];
}

- findSpecialList: (const char *) list named: (const char *) name
{
id tempList;
int i, j;

	for (i = 0 ; i < [protoSpecial count]; i++)
	{
		if (!strcmp(list, [[protoSpecial objectAt:i] name]))
		{
			tempList = [protoSpecial objectAt:i];
			for (j = 0; j < [tempList count]; j++)
			{
				if (!strcmp(name, [[tempList objectAt: j] name]))
					return [tempList objectAt: j];
			}
		}

	}
	return nil;
}

- findList: (int *) listIndex andIndex: (int *) index ofSpecial: transition
{
int i, temp;

	for (i = 0 ; i < [protoSpecial count]; i++)
	{
		temp = [[protoSpecial objectAt:i] indexOf:transition];
		if (temp != NX_NOT_IN_LIST)
		{
			*listIndex = i;
			*index = temp;
			return self;
		}

	}
	*listIndex = (-1);
	return self;
}

- findSpecial: (int) listIndex andIndex: (int) index
{
	return [[protoSpecial objectAt: listIndex] objectAt: index];
}

- (BOOL) isEquationUsed: anEquation
{
int i, j;
id tempList;

	for(i = 0; i<[protoTemplates count];i++)
	{
		tempList = [protoTemplates objectAt:i];
		for(j = 0; j<[tempList count]; j++)
		{
			if ([[tempList objectAt:j] isEquationUsed:anEquation])
				return YES;
		}
	}

	for(i = 0; i<[protoSpecial count];i++)
	{
		tempList = [protoSpecial objectAt:i];
		for(j = 0; j<[tempList count]; j++)
		{
			if ([[tempList objectAt:j] isEquationUsed:anEquation])
				return YES;
		}
	}
	return NO;

}

- readPrototypesFrom:(NXTypedStream *)stream
{
	[protoEquations free];
	[protoTemplates free];
	[protoSpecial free];

	protoEquations = NXReadObject(stream);
	protoTemplates = NXReadObject(stream);
	protoSpecial = NXReadObject(stream);
//	[[[protoTemplates objectAt: 0] objectAt:1] setType:3];
//	[[[protoTemplates objectAt: 0] objectAt:2] setType:4];

	return self;
}

- writePrototypesTo:(NXTypedStream *)stream
{
	NXWriteObject(stream, protoEquations);
	NXWriteObject(stream, protoTemplates);
	NXWriteObject(stream, protoSpecial);

	return self;
}

@end
