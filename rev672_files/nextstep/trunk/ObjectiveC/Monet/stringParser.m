#import <stdio.h>
#import <string.h>
#import <stdlib.h>
#import <ctype.h>
#import <AppKit/NSApplication.h>
#import "EventList.h"
#import "PhoneList.h"
#import "MyController.h"

static id	category[15];
static id	returnCategory[7];
static int	currentState;
static id	lastPhone;

void initStringParser()
{
PhoneList *mainPhoneList = (PhoneList *) NXGetNamedObject("mainPhoneList", NSApp);
CategoryList *mainCategoryList = (CategoryList *) NXGetNamedObject("mainCategoryList", NSApp);
Phone *tempPhone;
int dummy;

	category[0] = [mainCategoryList findSymbol:"stopped"];
	category[1] = [mainCategoryList findSymbol:"affricate"];
	category[2] = [mainCategoryList findSymbol:"hlike"];
	category[3] = [mainCategoryList findSymbol:"vocoid"];
	category[14] = [mainCategoryList findSymbol:"whistlehack"];

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
PhoneList *mainPhoneList = (PhoneList *) NXGetNamedObject("mainPhoneList", NSApp);
CategoryList *catList = [nextPhone categoryList];
Phone *tempPhone;

int i, dummy;
int transitionMade = 0;
const char *temp;
id returnValue = nil;

static int stateTable[17][15] =
{
	{1, 9, 0, 7, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 0},		/* State 0 */
	{3, 9, 0, 7, 2, 2, 2, 2, 5, 5, 13, 13, 15, 15, 0},		/* State 1 */
	{1, 9, 0, 7, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 0},		/* State 2 */
	{4, 9, 0, 7, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 0},		/* State 3 */
	{1, 9, 0, 7, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 0},		/* State 4 */
	{1, 9, 0, 6, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 0},		/* State 5 */
	{1, 9, 0, 8, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 0},		/* State 6 */
	{1, 9, 0, 8, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 0},		/* State 7 */
	{1, 9, 0, 8, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 0},		/* State 8 */
	{10, 12, 12, 0, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 0},		/* State 9 */
	{11, 11, 11, 0, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 0},		/* State 10 */
	{1, 9, 0, 0, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 0},		/* State 11 */
	{1, 9, 0, 0, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 0},		/* State 12 */
	{1, 9, 0, 0, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 14},		/* State 13 */
	{1, 9, 0, 0, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 0},		/* State 14 */
	{1, 9, 0, 0, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 16},		/* State 15 */
	{1, 9, 0, 0, 0, 0, 0, 0, 5, 5, 13, 13, 15, 15, 0},		/* State 16 */
};

	for (i = 0; i< 15; i++)
		if ([catList indexOfObject: category[i]] !=NSNotFound)
		{
			printf("Found %s %s state %d -> %d\n", [nextPhone symbol], [category[i] symbol], 
				currentState, stateTable[currentState][i]);
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
				if (index([lastPhone symbol], '\''))
					tempPhone = [mainPhoneList binarySearchPhone:"l'" index:&dummy];
				else
					tempPhone = [mainPhoneList binarySearchPhone:"l" index:&dummy];

				[eventList replaceCurrentPhoneWith:tempPhone];

				break;
			case 8:
				printf("vowels %s -> %s   %d\n", [lastPhone symbol], [nextPhone symbol], wordMarker);
				if ((nextPhone == lastPhone) && wordMarker)
				{
					returnValue = returnCategory[4];
				}
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
PhoneList *mainPhoneList = (PhoneList *) NXGetNamedObject("mainPhoneList", NSApp);
Phone *tempPhone, *tempPhone1;
int length, dummy;
int index = 0, bufferIndex = 0;
char buffer[128];
int lastFoot = 0, markedFoot = 0, wordMarker = 0;
double footTempo = 1.0;
double ruleTempo = 1.0;
double phoneTempo = 1.0;

	length = strlen(string);
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
						[eventList setCurrentToneGroupType:STATEMENT];
						break;
					case '1': /* Tone group 1. Exclaimation */
						index++;
						[eventList setCurrentToneGroupType:EXCLAIMATION];
						break;
					case '2': /* Tone group 2. Question */
						index++;
						[eventList setCurrentToneGroupType:QUESTION];
						break;
					case '3': /* Tone group 3. Continuation */
						index++;
						[eventList setCurrentToneGroupType:CONTINUATION];
						break;
					case '4': /* Tone group 4. Semi-colon */
						index++;
						[eventList setCurrentToneGroupType:SEMICOLON];
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
						index++;
//						printf("New Chunk\n");
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
						printf("Unknown \"/\" escape sequence :%c\n", string[index]);
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
					printf("Unknown character %c\n", string[index++]);
					break;
				}

		}


	}
	return (0);
}
