#import <stdio.h>
#import <string.h>
#import <stdlib.h>
#import <ctype.h>
#import <objc/objc.h>
#import <appkit/Application.h>
#import "EventList.h"
#import "PhoneList.h"
#import "CategoryList.h"

extern PhoneList *mainPhoneList;
extern CategoryList *mainCategoryList;
extern int vowelTransitions[13][13];


static id	category[18];
static id	returnCategory[7];
static int	currentState;
static id	lastPhone;

void initStringParser()
{
Phone *tempPhone;
int dummy;

	category[0] = [mainCategoryList findSymbol:"stopped"];
	category[1] = [mainCategoryList findSymbol:"affricate"];
	category[2] = [mainCategoryList findSymbol:"hlike"];
	category[3] = [mainCategoryList findSymbol:"vocoid"];
	category[14] = [mainCategoryList findSymbol:"whistlehack"];
	category[15] = [mainCategoryList findSymbol:"lhack"];

	tempPhone = [mainPhoneList binarySearchPhone:"h" index:&dummy];
	category[4] = [[tempPhone categoryList] findSymbol:"h"];

	tempPhone = [mainPhoneList binarySearchPhone:"h'" index:&dummy];
	category[5] = [[tempPhone categoryList] findSymbol:"h'"];

	tempPhone = [mainPhoneList binarySearchPhone:"hv" index:&dummy];
	category[6] = [[tempPhone categoryList] findSymbol:"hv"];

	tempPhone = [mainPhoneList binarySearchPhone:"hv'" index:&dummy];
	category[7] = [[tempPhone categoryList] findSymbol:"hv'"];

	tempPhone = [mainPhoneList binarySearchPhone:"ll" index:&dummy];
	category[8] = [[tempPhone categoryList] findSymbol:"ll"];

	tempPhone = [mainPhoneList binarySearchPhone:"ll'" index:&dummy];
	category[9] = [[tempPhone categoryList] findSymbol:"ll'"];

	tempPhone = [mainPhoneList binarySearchPhone:"s" index:&dummy];
	category[10] = [[tempPhone categoryList] findSymbol:"s"];

	tempPhone = [mainPhoneList binarySearchPhone:"s'" index:&dummy];
	category[11] = [[tempPhone categoryList] findSymbol:"s'"];

	tempPhone = [mainPhoneList binarySearchPhone:"z" index:&dummy];
	category[12] = [[tempPhone categoryList] findSymbol:"z"];

	tempPhone = [mainPhoneList binarySearchPhone:"z'" index:&dummy];
	category[13] = [[tempPhone categoryList] findSymbol:"z'"];

	tempPhone = [mainPhoneList binarySearchPhone:"l" index:&dummy];
	category[16] = [mainCategoryList findSymbol:"whistlehack"];

	tempPhone = [mainPhoneList binarySearchPhone:"l'" index:&dummy];
	category[17] = [mainCategoryList findSymbol:"whistlehack"];

	returnCategory[0] = [mainPhoneList binarySearchPhone:"qc" index:&dummy];
	returnCategory[1] = [mainPhoneList binarySearchPhone:"qt" index:&dummy];
	returnCategory[2] = [mainPhoneList binarySearchPhone:"qp" index:&dummy];
	returnCategory[3] = [mainPhoneList binarySearchPhone:"qk" index:&dummy];
	returnCategory[4] = [mainPhoneList binarySearchPhone:"gs" index:&dummy];
	returnCategory[5] = [mainPhoneList binarySearchPhone:"qs" index:&dummy];
	returnCategory[6] = [mainPhoneList binarySearchPhone:"qz" index:&dummy];

	currentState = 0;
	lastPhone = nil;

	return;
}

Phone *rewrite(nextPhone, eventList, wordMarker)
Phone *nextPhone;
EventList *eventList;
int wordMarker;
{
CategoryList *catList = [nextPhone categoryList];
Phone *tempPhone;

int i, dummy;
int transitionMade = 0;
const char *temp;
id returnValue = nil;

static int stateTable[19][18] = 
{
	{1, 9, 0, 7, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 0, 0, 0, 17},		/* State 0 */
	{3, 9, 0, 7, 2, 2, 2, 2, 5, 5, 13, 13, 15, 15, 0, 0, 0, 17},		/* State 1 */
	{1, 9, 0, 7, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 0, 0, 0, 17},		/* State 2 */
	{4, 9, 0, 7, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 0, 0, 0, 17},		/* State 3 */
	{1, 9, 0, 7, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 0, 0, 0, 17},		/* State 4 */
	{1, 9, 0, 6, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 0, 0, 0, 17},		/* State 5 */
	{1, 9, 0, 8, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 0, 0, 0, 17},		/* State 6 */
	{1, 9, 0, 8, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 0, 0, 0, 17},		/* State 7 */
	{1, 9, 0, 8, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 0, 0, 0, 17},		/* State 8 */
	{10, 12, 12, 0, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 0, 0, 0, 17},		/* State 9 */
	{11, 11, 11, 0, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 0, 0, 0, 17},		/* State 10 */
	{1, 9, 0, 0, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 0, 0, 0, 17},		/* State 11 */
	{1, 9, 0, 0, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 0, 0, 0, 17},		/* State 12 */
	{1, 9, 0, 0, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 14, 0, 0, 17},		/* State 13 */
	{1, 9, 0, 0, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 0, 0, 0, 17},		/* State 14 */
	{1, 9, 0, 0, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 16, 0, 0, 17},		/* State 15 */
	{1, 9, 0, 0, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 0, 0, 0, 17},		/* State 16 */
	{1, 9, 0, 0, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 0, 0, 18, 17},		/* State 17 */
	{1, 9, 0, 0, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 0, 0, 0, 17},		/* State 18 */
};

	for (i = 0; i< 18; i++)
		if ([catList indexOf: category[i]] !=NX_NOT_IN_LIST)
		{
//			printf("Found %s %s state %d -> %d\n", [nextPhone symbol], [category[i] symbol], 
//				currentState, stateTable[currentState][i]);
			currentState = stateTable[currentState][i];
			transitionMade = 1;
			break;
		}
	if (transitionMade)
	{
		switch(currentState)
		{
			default:
			case 0:
			case 1:
			case 3:
			case 5:
			case 7:
			case 9:	
//				printf("No rewrite\n");
				break;
			case 2: 
			case 4:
			case 11:
				temp = [lastPhone symbol];
				switch(temp[0])
				{
					case 'd':
					case 't': returnValue = returnCategory[1];
						break;
					case 'p':
					case 'b': returnValue = returnCategory[2];
						break;
					case 'k':
					case 'g': returnValue = returnCategory[3];
						break;
				}
				break;
			case 6:
				if (index([nextPhone symbol], '\''))
					tempPhone = [mainPhoneList binarySearchPhone:"l'" index:&dummy];
				else
					tempPhone = [mainPhoneList binarySearchPhone:"l" index:&dummy];

				[eventList replaceCurrentPhoneWith:tempPhone];

				break;
			case 8:
				if (wordMarker)
					returnValue = calcVowelTransition(nextPhone);

				break;
			case 10:
				returnValue = returnCategory[0];
				break;
			case 12:
				returnValue = returnCategory[0];
				break;
			case 14:
				returnValue = returnCategory[5];
				break;
			case 16:
				returnValue = returnCategory[6];
				break;
			case 18:
//				printf("Case 18\n");
				if (!wordMarker)
					break;

				if (index([nextPhone symbol], '\''))
					tempPhone = [mainPhoneList binarySearchPhone:"ll'" index:&dummy];
				else
					tempPhone = [mainPhoneList binarySearchPhone:"ll" index:&dummy];

//				printf("Replacing with ll\n");
				[eventList replaceCurrentPhoneWith:tempPhone];

				break;
		}
		lastPhone = nextPhone;
	}
	else
	{
		currentState = 0;
		lastPhone = nil;
	}
	return returnValue;
}

int parse_string(eventList, string)
id eventList;
char *string;
{
Phone *tempPhone, *tempPhone1;
int length, dummy;
int index = 0, bufferIndex = 0;
int chunk = 0;
char buffer[128];
int lastFoot = 0, markedFoot = 0, wordMarker = 0 ;
double footTempo = 1.0;
double ruleTempo = 1.0;
double phoneTempo = 1.0;

	length = strlen(string);

	tempPhone = [mainPhoneList binarySearchPhone:"^" index:&dummy];
	[eventList newPhoneWithObject:tempPhone];

	while(index<length)
	{
		while((isspace(string[index]) || (string[index] == '_')) && (index<length)) index++;
		if (index>length)
			break;

		bzero(buffer, 128);
		bufferIndex = 0;

		switch(string[index])
		{
			case '/': /* Handle "/" escape sequences */
				index++;
				switch(string[index])
				{
					case '0': /* Tone group 0. Statement */
						index++;
						[eventList setCurrentToneGroupType: STATEMENT];
						break;
					case '1': /* Tone group 1. Exclaimation */
						index++;
						[eventList setCurrentToneGroupType: EXCLAIMATION];
						break;
					case '2': /* Tone group 2. Question */
						index++;
						[eventList setCurrentToneGroupType: QUESTION];
						break;
					case '3': /* Tone group 3. Continuation */
						index++;
						[eventList setCurrentToneGroupType: CONTINUATION];
						break;
					case '4': /* Tone group 4. Semi-colon */
						index++;
						[eventList setCurrentToneGroupType: SEMICOLON];
						break;
					case ' ':
					case '_': /* New foot */
						[eventList newFoot];
						if (lastFoot)
							[eventList setCurrentFootLast];
						footTempo = 1.0;
						lastFoot = 0;
						markedFoot = 0;
						index++;
						break;
					case '*': /* New Marked foot */
						[eventList newFoot];
						[eventList setCurrentFootMarked];
						if (lastFoot)
							[eventList setCurrentFootLast];

						footTempo = 1.0;
						lastFoot = 0;
						markedFoot = 1;
						index++;
						break;
					case '/': /* New Tone Group */
						index++;
						[eventList newToneGroup];
						break;
					case 'c': /* New Chunk */
						if (chunk)
						{
							tempPhone = [mainPhoneList binarySearchPhone:"#" index:&dummy];
							[eventList newPhoneWithObject:tempPhone];
							tempPhone = [mainPhoneList binarySearchPhone:"^" index:&dummy];
							[eventList newPhoneWithObject:tempPhone];
							index--;
							return (index);
						}
						else
						{
							chunk++;
							index++;
						}
						break;
					case 'l': /* Last Foot in tone group marker */
						index++;
						lastFoot = 1;
						break;
					case 'w': /* word marker */
						index++;
						wordMarker = 1;
						break;
					case 'f': /* Foot tempo indicator */
						index++;
						while((isspace(string[index]) ||
							 (string[index] == '_')) && (index<length)) index++;
						if (index>length)
							break;
						while(isdigit(string[index]) || (string[index] == '.'))
						{
							buffer[bufferIndex++] = string[index++];
						}
						footTempo = atof(buffer);
						[eventList setCurrentFootTempo:footTempo];
						break;
					case 'r': /* Foot tempo indicator */
						index++;
						while((isspace(string[index]) ||
							 (string[index] == '_')) && (index<length)) index++;
						if (index>length)
							break;
						while(isdigit(string[index]) || (string[index] == '.'))
						{
							buffer[bufferIndex++] = string[index++];
						}
						ruleTempo = atof(buffer);
						break;
					default:
						index++;
//						printf("Unknown \"/\" escape sequence :%c\n", string[index]);
						break;
				}
				break;
			case '.': /* Syllable Marker */
				[eventList setCurrentPhoneSyllable];
				index++;
				break;

			case '0':
			case '1':
			case '2':
			case '3':
			case '4':
			case '5':
			case '6':
			case '7':
			case '8':
			case '9':
				while(isdigit(string[index]) || (string[index] == '.'))
				{
					buffer[bufferIndex++] = string[index++];
				}
				phoneTempo = atof(buffer);
				break;

			default:
				if (isalpha(string[index]) || (string[index] == '^') || (string[index] == '\'')
					|| (string[index] == '#') )
				{
					while( (isalpha(string[index])||(string[index] == '^')||(string[index] == '\'')
						||(string[index] == '#')) && (index<length))
						buffer[bufferIndex++] = string[index++];
					if (markedFoot)
						strcat(buffer,"'");
					tempPhone = [mainPhoneList binarySearchPhone:buffer index:&dummy];
					if (tempPhone)
					{
						tempPhone1 = rewrite(tempPhone, eventList, wordMarker);
						if (tempPhone1)
						{
							[eventList newPhoneWithObject:tempPhone1];
						}
						[eventList newPhoneWithObject:tempPhone];
						[eventList setCurrentPhoneTempo:phoneTempo];
						[eventList setCurrentPhoneRuleTempo:(float)ruleTempo];
					}
					phoneTempo = 1.0;
					ruleTempo = 1.0;
					wordMarker = 0;
				}
				else
				{
//					printf("Unknown character %c\n", string[index++]);
					break;
				}

		}


	}
	return (0);
}

id calcVowelTransition(nextPhone)
id nextPhone;
{
int vowelHash[13] = { 194, 201, 97, 101, 105, 111, 221, 117, 211, 216, 202, 215, 234 };
int lastValue, nextValue, i, action;
const char *temp;

	temp = [lastPhone symbol];
	lastValue = (int) temp[0];
	if (temp[1]!='\'')
		lastValue += (int) temp[1];

	for(i = 0; i<13; i++)
	{
		if (lastValue == vowelHash[i])
		{		
			lastValue = i;
			break;
		}
	}
	if (i == 13)
		return nil;

	temp = [nextPhone symbol];
	nextValue = (int) temp[0];
	if (temp[1]!='\'')
		nextValue += (int) temp[1];

	for(i = 0; i<13; i++)
	{
		if (nextValue == vowelHash[i])
		{		
			nextValue = i;
			break;
		}
	}
	if (i == 13)
		return nil;

	action = vowelTransitions[lastValue][nextValue];

	switch(action)
	{
		default:
		case 0:
			return nil;

		case 1:	return [mainPhoneList binarySearchPhone:"gs" index:&i];

		case 2:	return [mainPhoneList binarySearchPhone:"r" index:&i];
	}


	return nil;
}
