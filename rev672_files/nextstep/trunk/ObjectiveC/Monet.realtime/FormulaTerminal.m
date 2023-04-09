
#import "FormulaTerminal.h"
#import "SymbolList.h"
#import "Target.h"
#import "Rule.h"
#import <stdio.h>
#import <string.h>
#import <appkit/Application.h>		// for NXApp

extern SymbolList *mainSymbolList;

@implementation FormulaTerminal

- init
{
	symbol = nil;
	value = 0.0;

	whichPhone = (-1);

	precedence = 4;

	return self;
}

- setSymbol:newSymbol
{
	symbol = newSymbol;
	return self;
}

- symbol
{
	return symbol;
}

- setValue:(double) newValue
{
	value = newValue;
	return self;
}

- (double) value
{
	return value;
}

- setWhichPhone:(int) newValue
{
	whichPhone = newValue;
	return self;
}

- (int) whichPhone
{
	return whichPhone;
}

- setPrecedence: (int) newPrec
{
	precedence = newPrec;
	return self;
}

- (int) precedence
{
	return precedence;
}

- (double) evaluate:(double *) ruleSymbols phones: phones
{
double tempos[4] = {1.0, 1.0, 1.0, 1.0};
	return [self evaluate: ruleSymbols tempos: tempos phones: phones];
}

- (double) evaluate:(double *) ruleSymbols tempos: (double *) tempos phones: phones
{
Target *tempTarget;
int index;
int i;


	/* Duration of the rule itself */
	switch(whichPhone)
	{
		case RULEDURATION:
			return ruleSymbols[0];
		case BEAT:
			return ruleSymbols[1];
		case MARK1:
			return ruleSymbols[2];
		case MARK2:
			return ruleSymbols[3];
		case MARK3:
			return ruleSymbols[4];
		case TEMPO0:
			return tempos[0];
		case TEMPO1:
			return tempos[1];
		case TEMPO2:
			return tempos[2];
		case TEMPO3:
			return tempos[3];

		default:
			break;
	}

	/* Constant value */
	if (symbol==nil)
		return value;
	else
	/* Resolve the symbol*/
	{
		/* Get main symbolList to determine index of "symbol" */
		index = [mainSymbolList indexOf:symbol];

		/* Use index to index the phone's symbol list */
		tempTarget = [[[phones objectAt:whichPhone] symbolList] objectAt:index];

//		printf("Evaluate: %s Index: %d  Value : %f\n", [[phones objectAt: whichPhone] symbol], index, [tempTarget value]);

		/* Return the value */
		return [tempTarget value];
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

- (int) maxPhone
{
	return whichPhone;
}

- expressionString:(char *) string
{
char temp[256];

	switch(whichPhone)
	{
		case RULEDURATION:
			strcat(string, "rd");
			return self;
		case BEAT:
			strcat(string, "beat");
			return self;
		case MARK1:
			strcat(string, "mark1");
			return self;
		case MARK2:
			strcat(string, "mark2");
			return self;
		case MARK3:
			strcat(string, "mark3");
			return self;
		case TEMPO0:
			strcat(string, "tempo1");
			return self;
		case TEMPO1:
			strcat(string, "tempo2");
			return self;
		case TEMPO2:
			strcat(string, "tempo3");
			return self;
		case TEMPO3:
			strcat(string, "tempo4");
			return self;

		default:
			break;
	}
	if (symbol == nil)
	{
		sprintf(temp, "%f", value);
		strcat(string, temp);
	}
	else
	{
		sprintf(temp, "%s%d", [symbol symbol], whichPhone+1);
		strcat(string, temp);
	}

	return self;
}

- read:(NXTypedStream *)stream
{
char *string;
SymbolList *temp;


	[super read:stream];

	NXReadTypes(stream, "dii", &value, &whichPhone, &precedence);

	NXReadType(stream, "*", &string);
	if (!strcmp(string, "No Symbol"))
		symbol = nil;
	else
		symbol = [mainSymbolList findSymbol:string];

	free(string);
	return self;
}

- write:(NXTypedStream *)stream
{
const char *temp;

	[super write:stream];

	NXWriteTypes(stream, "dii", &value, &whichPhone, &precedence);

	if (symbol)
	{
		temp = [symbol symbol];
		NXWriteType(stream, "*", &temp);
	}
	else
	{
		temp = "No Symbol";
		NXWriteType(stream, "*", &temp);
	}

	return self;
}



@end
