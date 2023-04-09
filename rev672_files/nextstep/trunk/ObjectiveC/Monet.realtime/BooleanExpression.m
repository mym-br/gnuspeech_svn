
#import "BooleanExpression.h"
#import <string.h>
#import <stdlib.h>

@implementation BooleanExpression

- init
{
	numExpressions = 0;
	operation = NO_OP;

	/* Set up 4 sub expressions as the default.  Realloc later to increase */
	maxExpressions = 4;
	expressions = (id *) malloc (sizeof (id *) *4);

	/* Set all Sub-Expressions to nil */
	bzero(expressions, sizeof (id *) *4);

	return self;
}

- free
{
int i;

	for (i = 0; i<numExpressions; i++)
		[ expressions[i] free];
	free(expressions);
	[super free];

	return nil;
}



- (int) evaluate: (CategoryList *) categories
{
	switch(operation)
	{
		case NOT_OP: 
			return (![expressions[0] evaluate:categories]);
			break;

		case AND_OP: 
			if (![expressions[0] evaluate:categories]) return (0);
			return [expressions[1] evaluate:categories];
			break;

		case OR_OP: 
			if ([expressions[0] evaluate:categories]) return (1);
			return [expressions[1] evaluate:categories];
			break;

		case XOR_OP: 
			return ([expressions[0] evaluate:categories] ^ [expressions[1] evaluate:categories]);
			break;

		default: return 1;
	}
	return 0;
}



- setOperation:(int) newOp
{
	operation = newOp;
	return self;
}


- (int) operation
{
	return operation;
}


- addSubExpression: newExpression
{
	expressions[numExpressions] = newExpression;
	numExpressions++;
	return self;
}

- operandOne
{
	return expressions[0];
}


- optimize
{
	return self;
}


- optimizeSubExpressions
{
int i;
	for (i = 0 ; i<numExpressions; i++)
		[ expressions[i] optimizeSubExpressions];

	[self optimize];

	return self;
}


- (int) maxExpressionLevels
{
int i, max = 0;
int temp;

	for (i = 0 ; i<numExpressions; i++)
	{
		temp = [ expressions[i] maxExpressionLevels];
		if (temp>max)
			max = temp;
	}
	return max+1;
}


- expressionString:(char *) string
{
char buffer[1024];
char *opString;
int i;

	bzero(buffer, 1024);
	opString = [self opString];

//	printf("( ");
	strcat(string,"(");
	if (operation == NOT_OP)
	{
		strcat(string, "not ");
//		printf("not ");
		[ expressions[0] expressionString: string];

	}
	else
	for (i = 0 ; i<numExpressions; i++)
	{
		if (i!=0)
			strcat(string, opString);
//			printf(" %s ", opString);
		[ expressions[i] expressionString: string];

	}
	strcat(string,")");
//	printf(" )");

	return self;
}

- (char *) opString 
{
	switch(operation)
	{
		default:
		case NO_OP: return ("");
		case NOT_OP: return (" not ");
		case OR_OP: return (" or ");
		case AND_OP: return (" and ");
		case XOR_OP: return (" xor ");

	}
}

- (BOOL) isCategoryUsed: aCategory
{
int i;
	for (i = 0; i<numExpressions; i++)
	{
		if ([ expressions[i] isCategoryUsed:aCategory])
			return YES;
	}
	return NO;
}

- read:(NXTypedStream *)stream
{
int i;

	[super read:stream];

	NXReadTypes(stream, "iii", &operation, &numExpressions, &maxExpressions);
	expressions = (id *) malloc (sizeof (id *) *maxExpressions);


	for (i = 0; i<numExpressions; i++)
		expressions[i] = NXReadObject(stream);

	return self;
}

- write:(NXTypedStream *)stream
{
int i;

	[super write:stream];

	NXWriteTypes(stream, "iii", &operation, &numExpressions, &maxExpressions);
	for (i = 0; i<numExpressions; i++)
		NXWriteObject(stream, expressions[i]);


	return self;
}

@end
