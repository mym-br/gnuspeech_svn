
#import "FormulaExpression.h"
#import <string.h>
#import <stdlib.h>

@implementation FormulaExpression

- init
{
	numExpressions = 0;
	operation = END;

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
	[super free];

	return nil;
}

- setPrecedence:(int) newPrec
{
	precedence = newPrec;
	return self;
}

- (int) precedence
{
	return precedence;
}

- (double) evaluate: (double *) ruleSymbols phones: phones
{
double tempos[4] = {1.0, 1.0, 1.0, 1.0};

	return [self evaluate: ruleSymbols tempos: tempos phones: phones];
}

- (double) evaluate: (double *) ruleSymbols tempos: (double *) tempos phones: phones
{
	switch(operation)
	{
		case ADD: 
			return ([expressions[0] evaluate:ruleSymbols tempos: tempos phones: phones] + 
				[expressions[1] evaluate:ruleSymbols tempos: tempos phones:phones]);
			break;

		case SUB: 
			return ([expressions[0] evaluate:ruleSymbols tempos: tempos phones:phones] - 
				[expressions[1] evaluate:ruleSymbols tempos: tempos phones:phones]);
			break;

		case MULT: 
			return ([expressions[0] evaluate:ruleSymbols tempos: tempos phones:phones] *
				[expressions[1] evaluate:ruleSymbols tempos: tempos phones:phones]);
			break;

		case DIV: 
			return ([expressions[0] evaluate:ruleSymbols tempos: tempos phones:phones] /
				[expressions[1] evaluate:ruleSymbols tempos: tempos phones:phones]);
			break;

		default: return 1.0;
	}
	return 0.0;
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

- setOperandOne: operand
{
	expressions[0] = operand;
	if (expressions[0] == nil)
		numExpressions = 0;
	else 
	if (expressions[1] != nil)
		numExpressions = 2;
	else
		numExpressions = 1;
	return self;
}

- operandOne
{
	return expressions[0];
}

- setOperandTwo: operand
{
	expressions[1] = operand;
	if (operand!=nil)
		numExpressions = 2;
	return self;
}

- operandTwo
{
	return expressions[1];
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

- (int) maxPhone
{
int i, max = 0;
int temp;

	for (i = 0 ; i<numExpressions; i++)
	{
		temp = [ expressions[i] maxPhone];
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

	if (precedence == 3)
		strcat(string,"(");
	for (i = 0 ; i<numExpressions; i++)
	{
		if (i!=0)
			strcat(string, opString);
		[ expressions[i] expressionString: string];

	}
	if (precedence == 3)
		strcat(string,")");

	return self;
}

- (char *) opString 
{
	switch(operation)
	{
		default:
		case END: return ("");
		case ADD: return (" + ");
		case SUB: return (" - ");
		case MULT: return (" * ");
		case DIV: return (" / ");

	}
}

- read:(NXTypedStream *)stream
{
int i;

	[super read:stream];

	NXReadTypes(stream, "iiii", &operation, &numExpressions, &maxExpressions, &precedence);
	expressions = (id *) malloc (sizeof (id *) *maxExpressions);


	for (i = 0; i<numExpressions; i++)
		expressions[i] = NXReadObject(stream);

	return self;
}

- write:(NXTypedStream *)stream
{
int i;

	[super write:stream];

	NXWriteTypes(stream, "iiii", &operation, &numExpressions, &maxExpressions, &precedence);
	for (i = 0; i<numExpressions; i++)
		NXWriteObject(stream, expressions[i]);


	return self;
}


@end
