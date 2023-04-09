
#import "EventList.h"
#import <stdio.h>
#import <stdlib.h>
#import <string.h>
#import <mach/mach.h>
#import "Parameter.h"
#import "ProtoTemplate.h"
#import "ProtoEquation.h"
#import "Point.h"
#import "PhoneList.h"
#import "RuleList.h"
#import "tube_module/synthesizer_module.h"
#import "driftGenerator.h"
#import "IntonationPoint.h"
#import <dsp/dsp.h>
#import "structs.h"

extern id ruleList;
extern id mainParameterList;
extern id mainCategoryList;

extern struct _calc_info calc_info;

/*===========================================================================


===========================================================================*/

#define PAGES 8

static char	*outputBuffer;
static int	currentInputBuffer, currentOutputBuffer, currentConsumed;
static int	bufferFree[PAGES];
static int	currentIndex;

extern float **tg_parameters[5];
extern int tg_count[5];

void update_synth_ptr(void)
{
int next_page;
static count;

//	printf("\t\t\tSet Page %d\n", currentOutputBuffer);
	if (!bufferFree[currentOutputBuffer])
	{
		synth_read_ptr = outputBuffer+(currentOutputBuffer*vm_page_size);
		bufferFree[currentOutputBuffer] = 2;
		currentOutputBuffer = (currentOutputBuffer+1)%PAGES;
	}
}

void page_consumed(void)
{
int next_page;
static count;

//	printf("\t\t\t\t\t\tConsumed Page %d\n", currentConsumed);
	bufferFree[currentConsumed] = 1;
	currentConsumed = (currentConsumed+1)%PAGES;
}


@implementation EventList


- init
{
kern_return_t ret;

	[super init];
	ret = vm_allocate(task_self(), (vm_address_t *)&outputBuffer,vm_page_size*PAGES, TRUE);
	if (ret!=KERN_SUCCESS)
	{
		printf("UGH!  Cannot vm_allocate\n");
		return self;

	}
	cache = 10000000;
	[self setUp];

//	setDriftGenerator(1.0, 250.0, 4.0);
	setDriftGenerator(0.5, 250.0, 0.5);
	radiusMultiply = 1.0;

	intonationPoints = [[List alloc] initCount:4];

	return self;
}

- initCount:(unsigned int)numSlots
{
kern_return_t ret;

	[super initCount: numSlots];
	ret = vm_allocate(task_self(), (vm_address_t *)&outputBuffer,vm_page_size*PAGES, TRUE);
	if (ret!=KERN_SUCCESS)
	{
		printf("UGH!  Cannot vm_allocate\n");
		return self;

	}
	cache = 10000000;
	[self setUp];

	setDriftGenerator(0.5, 250.0, 0.5);
	radiusMultiply = 1.0;

	intonationPoints = [[List alloc] initCount:4];

	return self;
}

- free
{
	vm_deallocate(task_self(), (vm_address_t)outputBuffer,vm_page_size*PAGES);
	[super free];
	return nil;
}


- setUp
{
int i;
	[self freeObjects];
	zeroRef = 0;
	zeroIndex = 0;
	duration = 0;
	timeQuantization = 4;
	globalTempo = 1.0;
	multiplier = 1.0;
	macroFlag = 0;
	microFlag = 0;
	driftFlag = 0;
	intonParms = NULL;
	smoothIntonation = 1;

	/* set up buffer */
	bzero(outputBuffer, vm_page_size*PAGES);
	currentInputBuffer = currentOutputBuffer = currentConsumed = 0;
	currentIndex = 0;
	for (i = 0; i<PAGES; i++)
		bufferFree[i] = 1;

	bzero(phones, MAXPHONES * sizeof (struct _phone));
	bzero(feet, MAXFEET * sizeof (struct _foot));
	bzero(toneGroups, MAXTONEGROUPS * sizeof (struct _toneGroup));

	bzero(rules, MAXRULES * sizeof (struct _rule));

	currentPhone = 0;
	currentFoot = 0;
	currentToneGroup = 0;

	currentRule = 0;

	phoneTempo[0] = 1.0;
	feet[0].tempo = 1.0;

	return self;
}

- setZeroRef: (int) newValue
{
int i;
	zeroRef = newValue;
	zeroIndex = 0;

	if (numElements == 0) 
		return self;

	for (i = numElements-1; i>=0 ;i--)
	{
		if ([dataPtr[i] time] < newValue)
		{
			zeroIndex = i;
			return self;
		}

	}
	return self;
}

- (int) zeroRef
{
	return zeroRef;
}

- setDuration: (int) newValue
{
	duration = newValue;
	return self;
}

- (int) duration
{
	return duration;
}

- setRadiusMultiply: (double) newValue
{
	radiusMultiply = newValue;
	return self;
}

- (double) radiusMultiply
{
	return radiusMultiply;
}

- setFullTimeScale
{
	zeroRef = 0;
	zeroIndex = 0;
	duration = [dataPtr[numElements-1] time] + 100;
	return self;
}

- setTimeQuantization:(int) newValue
{
	timeQuantization = newValue;
	return self;
}

- (int) timeQuantization
{
	return timeQuantization;
}

- setParameterStore: (int) newValue
{
	parameterStore = newValue;
	return self;
}

- (int) parameterStore
{
	return parameterStore;
}

- setSoftwareSynthesis: (int) newValue
{
	softwareSynthesis = newValue;
	return self;
}

- (int) softwareSynthesis
{
	return softwareSynthesis;
}

- setPitchMean:(double) newMean
{
	pitchMean = newMean;
	return self;
}

-(double) pitchMean
{
	return pitchMean;
}

- setGlobalTempo:(double) newTempo
{
	globalTempo = newTempo;
	return self;
}

-(double) globalTempo;
{
	return globalTempo;
}

- setMultiplier:(double) newValue
{
	multiplier = newValue;
	return self;
}

-(double) multiplier
{
	return multiplier;
}

- setMacroIntonation: (int) newValue
{
	macroFlag = newValue;
	return self;
}

-(int) macroIntonation
{
	return macroFlag;
}

- setMicroIntonation: (int) newValue
{
	microFlag = newValue;
	return self;
}

-(int) microIntonation
{
	return microFlag;
}

- setDrift: (int) newValue
{
	driftFlag = newValue;
	return self;
}

-(int) drift
{
	return driftFlag;
}

- setSmoothIntonation: (int) newValue
{
	smoothIntonation = newValue;
	return self;
}

-(int) smoothIntonation
{
	return smoothIntonation;
}

- setIntonParms: (float *) newValue
{
	intonParms = newValue;
	return self;
}

-(float*) intonParms
{
	return intonParms;
}

- getPhoneAtIndex:(int) phoneIndex
{
	if (phoneIndex > currentPhone)
		return nil;
	else
		return phones[phoneIndex].phone;
}

- (struct _rule *) getRuleAtIndex: (int) ruleIndex
{
	if (ruleIndex > currentRule)
		return nil;
	else
		return &rules[ruleIndex];
}

- (double) getBeatAtIndex:(int) ruleIndex
{
	if (ruleIndex > currentRule)
		return 0.0;
	else
		return rules[ruleIndex].beat;
}

- (int) numberOfRules
{
	return currentRule;
}

/* Tone groups */

- newToneGroup
{
	if (currentFoot == 0)
		return self;

	toneGroups[currentToneGroup++].endFoot = currentFoot;
	[self newFoot];

	toneGroups[currentToneGroup].startFoot = currentFoot;
	toneGroups[currentToneGroup].endFoot = (-1);

	return self;
}

- setCurrentToneGroupType: (int) type
{
	toneGroups[currentToneGroup].type = type;
	return self;
}

/* Feet */

- newFoot
{
	if (currentPhone == 0)
		return self;

	feet[currentFoot++].end = currentPhone;
	[self newPhone];

	feet[currentFoot].start = currentPhone;
	feet[currentFoot].end = (-1);
	feet[currentFoot].tempo = 1.0;

	return self;
}

- setCurrentFootMarked
{
	feet[currentFoot].marked = 1;
	return self;	
}

- setCurrentFootLast
{
	feet[currentFoot].last = 1;
	return self;	
}

- setCurrentFootTempo:(double) tempo
{
	feet[currentFoot].tempo = tempo;
	return self;	
}

- newPhone
{
	if (phones[currentPhone].phone)
		currentPhone++;
	phoneTempo[currentPhone] = 1.0;
	return self;
}

- newPhoneWithObject: anObject
{
	if (phones[currentPhone].phone)
		currentPhone++;
	phoneTempo[currentPhone] = 1.0;
	phones[currentPhone].ruleTempo = 1.0;
	phones[currentPhone].phone = anObject;

	return self;
}

- replaceCurrentPhoneWith:anObject
{
	if (phones[currentPhone].phone)
		phones[currentPhone].phone = anObject;
	else
		phones[currentPhone-1].phone = anObject;
	return self;
}

- setCurrentPhoneTempo:(double) tempo
{
	phoneTempo[currentPhone] = tempo;
	return self;	
}

- setCurrentPhoneRuleTempo:(float) tempo
{
	phones[currentPhone].ruleTempo = tempo;
	return self;
}

- setCurrentPhoneSyllable
{
	phones[currentPhone].syllable = 1;
	return self;
}

- insertEvent:(int) number atTime: (double) time withValue: (double) value
{
Event *tempEvent = nil;
int i, tempTime;

	time = time*multiplier;
	if (time < 0.0) 
		return nil;
	if (time > (double) (duration+timeQuantization))
		return nil;

	tempTime = zeroRef + (int) time;
	tempTime = (tempTime>>2) <<2;
//	if ((tempTime%timeQuantization) !=0)
//		tempTime++;


	if (numElements == 0)
	{
		tempEvent = [[Event alloc] init];
		[tempEvent setTime: tempTime];
		if (number>=0)
				[tempEvent setValue: value ofIndex: number];

		[self addObject: tempEvent];
		return tempEvent;
	}

	for (i = numElements-1; i>=zeroIndex; i--)
	{
		if ([dataPtr[i] time]==tempTime)
		{
			if (number>=0)
				[dataPtr[i] setValue: value ofIndex: number];
			return dataPtr[i];
		}

		if ([dataPtr[i] time]< tempTime)
		{
			tempEvent = [[Event alloc] init];
			[tempEvent setTime: tempTime];
			if (number>=0)
				[tempEvent setValue: value ofIndex: number];

			[self insertObject:tempEvent at:i+1];
			return tempEvent;
		}
	}


	tempEvent = [[Event alloc] init];
	[tempEvent setTime: tempTime];
	if (number>=0)
		[tempEvent setValue: value ofIndex: number];

	[self insertObject: tempEvent at:i+1];
	return tempEvent;

}

- finalEvent:(int) number withValue: (double) value
{
Event *tempEvent;

	tempEvent = dataPtr[numElements-1];
	[tempEvent setValue: value ofIndex: number];
	[tempEvent setFlag:1];

	return self;
}

- lastEvent
{
	return dataPtr[numElements-1];
}

- generateOutput
{
int i, j, k;
int currentTime, nextTime;
int watermark = 0;
double currentValues[36];
double currentDeltas[36];
double temp;
float table[16];
FILE *fp;
float silencePage[16] = {0.0, 0.0, 0.0, 0.0, 5.5, 2500.0, 500.0, 0.8, 0.89, 0.99, 0.81, 0.76, 1.05, 1.23, 0.01, 0.0};
DSPFix24 *silenceTable;

	if (numElements==0)
		return self;
	if (parameterStore)
	{
		fp = fopen("/tmp/Monet.parameters", "w");
	}
	else
	if (softwareSynthesis)
	{
		fp = fopen("/tmp/Monet.parameters", "a+");
	}
	else
		fp = NULL;

	currentTime = 0;
	for (i = 0; i< 16; i++)
	{
		j = 1;
		while( ( temp = [dataPtr[j] getValueAtIndex:i]) == NaN) j++;
		currentValues[i] = [dataPtr[0] getValueAtIndex:i];
		currentDeltas[i] = ((temp - currentValues[i]) / (double) ([dataPtr[j] time])) * 4.0;
	}
	for(i = 16; i<32; i++)
		currentValues[i] = currentDeltas[i] = 0.0;

	if (smoothIntonation)
	{
	       j = 0;
		while( ( temp = [dataPtr[j] getValueAtIndex:32]) == NaN)
		{
			j++;
			if (j>=numElements) break;
		}
		currentValues[32] = [dataPtr[j] getValueAtIndex:32];
		currentDeltas[32] = 0.0;
	}
	else
	{
		j = 1;
		while( ( temp = [dataPtr[j] getValueAtIndex:32]) == NaN)
		{
			j++;
			if (j>=numElements) break;
		}
		currentValues[32] = [dataPtr[0] getValueAtIndex:32];
		if (j<numElements)
			currentDeltas[32] = ((temp - currentValues[32]) / (double) ([dataPtr[j] time])) * 4.0;
		else
			currentDeltas[32] = 0;
		currentValues[32] = -20.0;
	}

	i = 1;
	currentTime = 0;
	nextTime = [dataPtr[1] time];
	while(i < numElements)
	{

		/* If buffer space is available, perform calculations */
		if ((bufferFree[currentInputBuffer]==1) || softwareSynthesis)
		{
			bzero(outputBuffer + (currentInputBuffer*vm_page_size), 8192);
			while(currentIndex<8192)
			{

				for(j = 0 ; j<16; j++)
				{
					table[j] = (float) currentValues[j] + (float) currentValues[j+16];
				}
				if (!microFlag)
					table[0] = 0.0;

				if (driftFlag)
					table[0] += drift();

				if (macroFlag)
					table[0] += currentValues[32];

				table[0]+=pitchMean;

				if (fp)
				fprintf(fp, 
				  "%.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f\n", 
				  table[0], table[1], table[2], table[3], 
				  table[4], table[5], table[6], table[7], 
				  table[8], table[9], table[10], table[11], 
				  table[12], table[13], table[14], table[15]);

				convert_parameter_table(table, outputBuffer + (currentInputBuffer*vm_page_size) + currentIndex);

				currentIndex+=128;

				for(j = 0 ; j<32; j++)
				{
					if (currentDeltas[j])
						currentValues[j] += currentDeltas[j];
				}

				if (smoothIntonation)
				{
					currentDeltas[34]+=currentDeltas[35];
					currentDeltas[33]+=currentDeltas[34];
					currentValues[32]+=currentDeltas[33];
				}
				else
				{
					if (currentDeltas[32])
						currentValues[32] += currentDeltas[32];
				}
				currentTime+=4;

				if (currentTime>=nextTime)
				{
					i++;
					if (i==numElements)
						break;
					nextTime = [dataPtr[i] time];
					for (j = 0 ; j< 33; j++) /* 32? 33? */
					{
						if ([dataPtr[i-1] getValueAtIndex:j] !=NaN)
						{
							k = i;
							while(( temp = [dataPtr[k] getValueAtIndex:j]) == NaN) 
							{
								if (k>=numElements-1)
								{
									currentDeltas[j] = 0.0;
									break;
								}
								k++;
							}

							if (temp!=NaN)
							{
								currentDeltas[j] = (temp - currentValues[j]) / 
									(double) ([dataPtr[k] time] - currentTime) * 4.0;
							}
						}
					}
					if (smoothIntonation)
					{
						if ([dataPtr[i-1] getValueAtIndex:33]!=NaN)
						{
							currentValues[32] = [dataPtr[i-1] getValueAtIndex:32];
							currentDeltas[32] = 0.0;
							currentDeltas[33] = [dataPtr[i-1] getValueAtIndex:33];
							currentDeltas[34] = [dataPtr[i-1] getValueAtIndex:34];
							currentDeltas[35] = [dataPtr[i-1] getValueAtIndex:35];
						}
					}
				}
				if (i>=numElements) break;
			}

			poll_port(FALSE);

			if (i>=numElements) break;
			if (currentIndex >=8192)
			{
//				printf("Calculated table %d\n", currentInputBuffer);
				bufferFree[currentInputBuffer] = 0;
				currentIndex = 0;
				currentInputBuffer = (currentInputBuffer+1)%PAGES;
				watermark++;
			}
		}

		poll_port(FALSE);
		
		if ((calc_info.status==IDLE) && !softwareSynthesis)
			if(start_synthesizer()==ST_NO_ERROR)
				calc_info.status = RUNNING;

		if (!softwareSynthesis)
			feed_synthesizer(FALSE, FALSE);

		if (calc_info.status == ERASED)
		{
			if (fp)
				fclose(fp);
			return self;
		}
	}

	if ((calc_info.status==IDLE) && !softwareSynthesis)
		if(start_synthesizer()==ST_NO_ERROR)
			calc_info.status = RUNNING;
//		else 
//			printf("Cannot start Synth\n");

	if (currentIndex < 8192)
	{
		if (softwareSynthesis)
		{
			fclose(fp);
			fp = NULL;
			return self;
		}
		if (fp)
			fprintf(fp, "Start of Padding\n");
		silenceTable = new_dsp_pad_table(silencePage);
		for(i = 0; i<16; i++)
			currentValues[i] = (double) DSPFix24ToFloat(silenceTable[i]);
		while(currentIndex<8192)
		{
			bcopy(silenceTable, outputBuffer + (currentInputBuffer*vm_page_size) + currentIndex, 128);
			currentIndex+=128;
			if (fp)
				fprintf(fp, 
				  "Time: %d; %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f\n", 
				  currentTime, currentValues[0], currentValues[1], currentValues[2], currentValues[3], 
				  currentValues[4], currentValues[5], currentValues[6], currentValues[7], 
				  currentValues[8], currentValues[9], currentValues[10], currentValues[11], 
				  currentValues[12], currentValues[13], currentValues[14], currentValues[15]);
			currentTime+=4;
		}
		if (fp)
			fprintf(fp, "End of Padding\n");
		bufferFree[currentInputBuffer] = 0;
		free(silenceTable);
	}
	else
	{
		bufferFree[currentInputBuffer] = 0;
	}

	if (fp)
		fclose(fp);

	while(bufferFree[currentOutputBuffer]!=1)
	{
		if (bufferFree[(currentOutputBuffer+1)%PAGES])
		{
			if (!softwareSynthesis)
				feed_synthesizer(TRUE, TRUE);
		}
		else
		{
			if (!softwareSynthesis)
				feed_synthesizer(FALSE, FALSE);
		}

		if (calc_info.status == ERASED)
			break;

		poll_port(FALSE);
	}


	return self;

}

feed_synthesizer(block, last)
int block, last;
{

	while(1)
	{
		switch(calc_info.status)
		{
			case IDLE:
			case PAUSED: poll_port(FALSE);
					if (!block) return(0);
					break;

			case TO_BE_PAUSED:
					pause_synth();
					if (!block) return(0);
					break;
			case TO_BE_ERASED:
					pause_synth();
					calc_info.status = ERASED;
					return(0);

			case ERASED: return(0);

			case RUNNING:
			default:
					if (last)
					{

						await_request_new_page(ST_YES, ST_YES, update_synth_ptr, page_consumed);
						return 0;
					}
					else
						await_request_new_page(ST_NO, ST_NO, update_synth_ptr, page_consumed);
					if (!block) return(0);
		}
		poll_port(FALSE);
	}
}

void pause_synth()
{
//	printf("Pause Synth = %d\n", calc_info.status);
	await_request_new_page(ST_YES, ST_YES, update_synth_ptr, page_consumed);
	calc_info.status = PAUSED;
}

void continue_synth()
{
//	printf("Continue Synth status = %d\n", calc_info.status);
	switch(calc_info.status)
	{
		case PAUSED:
				if (start_synthesizer()==ST_NO_ERROR)
				{
					calc_info.status = RUNNING;
				}
//				else
//				printf("Cannot Restart synth in Continue Synthesizer\n");
				break;
		case TO_BE_PAUSED:
				calc_info.status = RUNNING;
				break;
		case IDLE:
		default:
				break;
	}
}

- printDataStructures
{
int i;
	printf("Tone Groups %d\n", currentToneGroup);
	for (i = 0; i<currentToneGroup;i++)
	{
		printf("%d  start: %d  end: %d  type: %d\n", i, toneGroups[i].startFoot, toneGroups[i].endFoot, 
			toneGroups[i].type);
	}

	printf("\nFeet %d\n", currentFoot);
	for (i = 0; i<currentFoot;i++)
	{
		printf("%d  tempo: %f start: %d  end: %d  marked: %d last: %d onset1: %f onset2: %f\n", i, feet[i].tempo,
			feet[i].start, feet[i].end, feet[i].marked, feet[i].last, feet[i].onset1, feet[i].onset2);
	}

	printf("\nPhones %d\n", currentPhone);
	for (i = 0; i<currentPhone;i++)
	{
		printf("%d  \"%s\" tempo: %f syllable: %d onset: %f ruleTempo: %f\n",
			 i, [phones[i].phone symbol], phoneTempo[i], phones[i].syllable, phones[i].onset, phones[i].ruleTempo);
	}

	printf("\nRules %d\n", currentRule);
	for (i = 0; i<currentRule;i++)
	{
		printf("Number: %d  start: %d  end: %d  duration %f\n", rules[i].number, rules[i].firstPhone, 
			rules[i].lastPhone, rules[i].duration);
	}


	return self;
}

- generateEventList
{
List *tempPhoneList, *tempCategoryList;
double tempoList[4];
double footTempo, tempTempo;
int index = 0, foot = 0;
int i, j, rus;
int ruleIndex;
Rule *tempRule;
Parameter *tempParameter = nil;

	for(i = 0; i<16; i++)
	{
		tempParameter = [mainParameterList objectAt: i];

		min[i] = (double) [tempParameter minimum];
		max[i] = (double) [tempParameter maximum];
	}

	tempPhoneList = [[List alloc] initCount:4];
	tempCategoryList = [[List alloc] initCount:4];
	bzero(tempoList, sizeof(double)*4);

	/* Calculate Rhythm including regression */
	for (i = 0; i<currentFoot;i++)
	{
		rus = feet[i].end - feet[i].start + 1;
		/* Apply rhythm model */
		if (feet[i].marked)
		{
			tempTempo = 117.7 - (19.36 * (double) rus);
			feet[i].tempo -= tempTempo/180.0;
			footTempo = globalTempo * feet[i].tempo;
		}
		else
		{
			tempTempo = 18.5 - (2.08 * (double) rus);
			feet[i].tempo -= tempTempo/140.0;
			footTempo = globalTempo * feet[i].tempo;
		}
		for (j = feet[i].start; j<feet[i].end+1; j++)
		{
			phoneTempo[j]*=footTempo;
			if (phoneTempo[j]<0.2)
				phoneTempo[j] = 0.2;
			else
			if (phoneTempo[j]>2.0)
				phoneTempo[j] = 2.0;

		}
	}

	while(index<currentPhone-1)
	{
		[tempPhoneList empty];
		[tempCategoryList empty];
		i = index;
		for(j = 0; j<4; j++)
		{
			[tempPhoneList addObject: phones[j+i].phone];
			[tempCategoryList addObject: [phones[j+i].phone categoryList]];
		}
		tempRule = [ruleList findRule: tempCategoryList index: &ruleIndex];

		rules[currentRule].number = ruleIndex+1;

		[self applyRule: tempRule withPhones: tempPhoneList andTempos: &phoneTempo[i] phoneIndex: i+1 ];

		index+=[tempRule numberExpressions]-1;
	}

	[tempPhoneList free];
	[tempCategoryList free];

//	[dataPtr[numElements-1] setFlag:1];
	
	return self;
}

- applyRule: rule withPhones: phoneList andTempos: (double *) tempos phoneIndex: (int) phoneIndex;
{
int i, j, type, cont;
int currentType;
double currentDelta, value, maxValue;
double ruleSymbols[5], tempTime, targets[4];
ProtoTemplate *protoTemplate;
Point *currentPoint;
List *tempTargets, *points;
Event *tempEvent;

	bzero(ruleSymbols, sizeof(double)*5);
	[rule evaluateExpressionSymbols: ruleSymbols tempos: tempos phones: phoneList withCache: (int) ++cache];

	multiplier = 1.0/(double) (phones[phoneIndex-1].ruleTempo);

	type = [rule numberExpressions];
	[self setDuration: (int) (ruleSymbols[0]*multiplier)];

	rules[currentRule].firstPhone = phoneIndex-1;
	rules[currentRule].lastPhone = phoneIndex-2+type;
	rules[currentRule].beat = (ruleSymbols[1]*multiplier) + (double) zeroRef;
	rules[currentRule++].duration = ruleSymbols[0]*multiplier;

	switch(type)
	{
		/* Note: Case 4 should execute all of the below, case 3 the last two */
		case 4: phones[phoneIndex+2].onset = (double) zeroRef + ruleSymbols[1];
			tempEvent = [self insertEvent:(-1) atTime: ruleSymbols[3] withValue: 0.0 ];
			[tempEvent setFlag:1];
		case 3: phones[phoneIndex+1].onset = (double) zeroRef + ruleSymbols[1];
			tempEvent = [self insertEvent:(-1) atTime: ruleSymbols[2] withValue: 0.0 ];
			[tempEvent setFlag:1];
		case 2: 
			phones[phoneIndex].onset = (double) zeroRef + ruleSymbols[1];
			tempEvent = [self insertEvent:(-1) atTime: 0.0 withValue: 0.0 ];
			[tempEvent setFlag:1];
			break;
	}

	tempTargets = (List *) [rule parameterList];


	/* Loop through the parameters */
	for(i = 0; i< [tempTargets count]; i++)
	{
		/* Get actual parameter target values */
		targets[0] = [[[[phoneList objectAt: 0] parameterList] objectAt: i] value];
		targets[1] = [[[[phoneList objectAt: 1] parameterList] objectAt: i] value];
		targets[2] = [[[[phoneList objectAt: 2] parameterList] objectAt: i] value];
		targets[3] = [[[[phoneList objectAt: 3] parameterList] objectAt: i] value];


		/* Optimization, Don't calculate if no changes occur */
		cont = 1;
		switch(type)
		{
			case DIPHONE: 
				if (targets[0] == targets[1]) 
					cont = 0;
				break;
			case TRIPHONE: 
				if ((targets[0] == targets[1]) && (targets[0] == targets[2]))
					cont = 0;
				break;
			case TETRAPHONE: 
				if ((targets[0] == targets[1]) && (targets[0] == targets[2]) && (targets[0] == targets[3]))
					cont = 0;
				break;
		}

		if (cont)
		{
			currentType = DIPHONE;
			currentDelta = targets[1] - targets[0];

			/* Get transition profile list */
			protoTemplate = (ProtoTemplate *) [tempTargets objectAt: i];
			points = [protoTemplate points];

			maxValue = 0.0;

			/* Apply lists to parameter */
			for(j = 0; j<[points count]; j++)
			{
				currentPoint = [points objectAt:j];



				if ([currentPoint isKindOfClassNamed:"SlopeRatio"])
				{
					if ([[[currentPoint points] objectAt: 0] type]!=currentType)
					{
						currentType = [[[currentPoint points] objectAt:0] type];
						targets[currentType-2] = maxValue;
						currentDelta = targets[currentType-1] - (maxValue);
					}
				}
				else
				{
					if ([currentPoint type] != currentType)
					{
						currentType = [currentPoint type];
						targets[currentType-2] = maxValue;
						currentDelta = targets[currentType-1] - (maxValue);
					}

				}
				maxValue = [currentPoint calculatePoints: ruleSymbols tempos: tempos phones: phoneList
					andCacheWith: cache baseline: targets[currentType-2] delta: currentDelta 
					min: min[i] max: max[i] toEventList: self atIndex: (int) i];
			}
		}
		else
		{
			tempEvent = [self insertEvent:i atTime: 0.0 withValue: targets[0] ];
		}
	}

	/* Special Event Profiles */
	for(i = 0; i<16; i++)
	{
		if (protoTemplate = [rule getSpecialProfile:i])
		{
			/* Get transition profile list */
			points = [protoTemplate points];

			for(j = 0; j<[points count]; j++)
			{
				currentPoint = [points objectAt:j];

				/* calculate time of event */
				if ([currentPoint expression]==nil)
					tempTime = [currentPoint freeTime];
				else
					tempTime = [ [ currentPoint expression] 
						evaluate: ruleSymbols tempos: tempos phones: phoneList andCacheWith: (int) cache];

				/* Calculate value of event */
				value = (([currentPoint value]/100.0) * (max[i] - min[i]));
				maxValue = value;

				/* insert event into event list */
				[self insertEvent:i+16 atTime: tempTime withValue: value];
			}
		}
	}

	[self setZeroRef: (int) (ruleSymbols[0]*multiplier) +  zeroRef];
	tempEvent = [self insertEvent:(-1) atTime: 0.0 withValue: 0.0 ];
	[tempEvent setFlag:1];

	return self;
}

- synthesizeToFile: (const char *) filename
{
	set_synthesizer_output(filename, getuid(), getgid(), 1);
	return self;
}

- applyIntonation
{
id vocoidCategory;
int tGroup=0, rule, tg_random;
int firstFoot, endFoot;
int ruleIndex, phoneIndex;
int i, j, k;
id tempEvent;
float tempIntonParms[5] = {0.0, 0.0, -1.0, 4.0, 0.0, -8.0, 8.0};
double startTime, endTime, pretonicDelta, offsetTime = 0.0;
double randomSemitone, randomSlope;

	zeroRef = 0;
	zeroIndex = 0;
	duration = [dataPtr[numElements-1] time] + 100;

	[intonationPoints freeObjects];

	vocoidCategory = [mainCategoryList findSymbol: "vocoid"];


	for (i = 0; i<currentToneGroup; i++)
	{
		firstFoot = toneGroups[i].startFoot;
		endFoot = toneGroups[i].endFoot;

		startTime  = phones[feet[firstFoot].start].onset;
		endTime  = phones[feet[endFoot].end].onset;

//		printf("Tg: %d First: %d  end: %d  StartTime: %f  endTime: %f\n", i, firstFoot, endFoot, startTime, endTime);

		if (!tg_parameters)
			intonParms = tempIntonParms;
		else
		{
			switch(toneGroups[i].type)
			{
				default:
				case STATEMENT:
					if (calc_info.random)
						tg_random = random()%tg_count[0];
					else
						tg_random = 0;
					intonParms = (float*)((int)tg_parameters[0]+(tg_random*40));
					break;
				case EXCLAIMATION:
					if (calc_info.random)
						tg_random = random()%tg_count[0];
					else
						tg_random = 0;
					intonParms = (float*)((int)tg_parameters[0]+(tg_random*40));
					break;
				case QUESTION:
					if (calc_info.random)
						tg_random = random()%tg_count[1];
					else
						tg_random = 0;
					intonParms = (float*)((int)tg_parameters[1]+(tg_random*40));
					break;
				case CONTINUATION:
					if (calc_info.random)
						tg_random = random()%tg_count[2];
					else
						tg_random = 0;
					intonParms = (float*)((int)tg_parameters[2]+(tg_random*40));
					break;
				case SEMICOLON:
					if (calc_info.random)
						tg_random = random()%tg_count[3];
					else
						tg_random = 0;
					intonParms = (float*)((int)tg_parameters[3]+(tg_random*40));
					break;
			}

//			printf("Intonation Parameters: Type : %d  random: %d\n", toneGroups[i].type, tg_random);
//			for (j = 0; j<6; j++)
//				printf("%f ", intonParms[j]);
//			printf("\n");
		}

		pretonicDelta = (intonParms[1])/(endTime - startTime);
//		printf("Pretonic Delta = %f time = %f\n", pretonicDelta, (endTime - startTime));

		/* Set up intonation boundary variables */
		for(j = firstFoot; j<=endFoot; j++)
		{
			phoneIndex = feet[j].start;
			while ([[phones[phoneIndex].phone categoryList] indexOf:vocoidCategory]==NX_NOT_IN_LIST)
			{
				phoneIndex++;
//				printf("Checking phone %s for vocoid\n", [phones[phoneIndex].phone symbol]);
				if (phoneIndex>feet[j].end)
				{
					phoneIndex = feet[j].start;
					break;
				}
			}

			if (!feet[j].marked)
			{
				for(k = 0; k<currentRule; k++)
				{
					if ((phoneIndex>=rules[k].firstPhone) && (phoneIndex<=rules[k].lastPhone))
					{
						ruleIndex = k;
						break;
					}
				}

				if (calc_info.random)
				{
					randomSemitone = ((double) random()/ (double) 0x7fffffff) * (double) intonParms[3] - 
						intonParms[3]/2.0; 
					randomSlope = ((double) random()/ (double) 0x7fffffff)*0.015 + 0.01;
				}
				else
				{
					randomSemitone = 0.0;
					randomSlope = 0.02;
				}

//				printf("phoneIndex = %d onsetTime : %f Delta: %f\n", phoneIndex,
//					phones[phoneIndex].onset-startTime,
//					((phones[phoneIndex].onset-startTime)*pretonicDelta) + intonParms[1] + randomSemitone);

				[self addPoint: ((phones[phoneIndex].onset-startTime)*pretonicDelta) + intonParms[1] +
					randomSemitone 
					offsetTime:offsetTime slope: randomSlope ruleIndex: ruleIndex eventList: self];

			}
			else
			/* Tonic */
			{
				if (toneGroups[i].type ==3)
					randomSlope = 0.01;
				else
					randomSlope = 0.02;

				for(k = 0; k<currentRule; k++)
				{
					if ((phoneIndex>=rules[k].firstPhone) && (phoneIndex<=rules[k].lastPhone))
					{
						ruleIndex = k;
						break;
					}
				}

				if (calc_info.random)
				{
					randomSemitone = ((double) random()/ (double) 0x7fffffff) * (double) intonParms[6] -
						intonParms[6]/2.0;
					randomSlope += ((double) random()/ (double) 0x7fffffff)*0.03;
				}
				else
				{
					randomSemitone = 0.0;
					randomSlope+= 0.03;
				}
				[self addPoint: intonParms[2] + intonParms[1] + randomSemitone
					offsetTime:offsetTime slope: randomSlope ruleIndex: ruleIndex eventList: self];

				phoneIndex = feet[j].end;
				for(k = ruleIndex; k<currentRule; k++)
				{
					if ((phoneIndex>=rules[k].firstPhone) && (phoneIndex<=rules[k].lastPhone))
					{
						ruleIndex = k;
						break;
					}
				}

				[self addPoint: intonParms[2] + intonParms[1] +intonParms[5]
					offsetTime:0.0 slope: 0.0 ruleIndex: ruleIndex eventList: self];


			}
			offsetTime = -40.0;
		}
	}
	[self addPoint: intonParms[2] + intonParms[1] + intonParms[5] 
		offsetTime:0.0 slope: 0.0 ruleIndex: currentRule-1 eventList: self];

	return self;
}

- applyIntonationSmooth
{
int j;
id point1, point2;
id tempPoint;
double a, b, c, d;
double x1, y1, m1, x12, x13;
double x2, y2, m2, x22, x23;
double denominator;
double yTemp;

	[self setFullTimeScale];
//	tempPoint = [[IntonationPoint alloc] initWithEventList: self];
//	[tempPoint setSemitone: -20.0];
//	[tempPoint setSemitone: -20.0];
//	[tempPoint setRuleIndex: 0];
//	[tempPoint setOffsetTime: 10.0 - [self getBeatAtIndex:(int) 0]];

//	[intonationPoints insertObject: tempPoint at:0];

	for (j = 0; j<[intonationPoints count]-1; j++)
	{
		point1 = [intonationPoints objectAt: j];
		point2 = [intonationPoints objectAt: j+1];

		x1 = [point1 absoluteTime]/4.0;
		y1 = [point1 semitone]+20.0;
		m1 = [point1 slope];

		x2 = [point2 absoluteTime]/4.0;
		y2 = [point2 semitone]+20.0;
		m2 = [point2 slope];

		x12 = x1*x1;
		x13 = x12*x1;

		x22 = x2*x2;
		x23 = x22*x2;

		denominator = (x2 - x1);
		denominator = denominator * denominator * denominator;

		d = ( -(y2*x13) + 3*y2*x12*x2 + m2*x13*x2 + m1*x12*x22 - m2*x12*x22 - 3*x1*y1*x22 - m1*x1*x23 + y1*x23)
			/ denominator;
		c = ( -(m2*x13) - 6*y2*x1*x2 - 2*m1*x12*x2 - m2*x12*x2 + 6*x1*y1*x2 + m1*x1*x22 + 2*m2*x1*x22 + m1*x23 )
			/ denominator;
		b = ( 3*y2*x1 + m1*x12 + 2*m2*x12 - 3*x1*y1 + 3*x2*y2 + m1*x1*x2 - m2*x1*x2 - 3*y1*x2 - 2*m1*x22 - m2*x22 )
			/ denominator;
		a = ( -2*y2 - m1*x1 - m2*x1 + 2*y1 + m1*x2 + m2*x2)/ denominator;

		[self insertEvent:32 atTime: [point1 absoluteTime] withValue: [point1 semitone]];
//		printf("Inserting Point %f\n", [point1 semitone]);
		yTemp = ((3.0*a*x12) + (2.0*b*x1) + c) ;
		[self insertEvent:33 atTime: [point1 absoluteTime] withValue: yTemp];
		yTemp = ((6.0*a*x1) + (2.0*b)) ;
		[self insertEvent:34 atTime: [point1 absoluteTime] withValue: yTemp];
		yTemp = (6.0*a);
		[self insertEvent:35 atTime: [point1 absoluteTime] withValue: yTemp];

	}
//	[intonationPoints removeObjectAt:0];

//	[self insertEvent:32 atTime: 0.0 withValue: -20.0]; /* A value of -20.0 in bin 32 should produce a 
//								    linear interp to -20.0 */
	return self;
}

- addPoint:(double) semitone offsetTime:(double) offsetTime slope:(double) slope ruleIndex:(int)ruleIndex eventList: anEventList
{
IntonationPoint *iPoint;

	iPoint = [[IntonationPoint alloc] initWithEventList: anEventList];
	[iPoint setRuleIndex: ruleIndex];
	[iPoint setOffsetTime: offsetTime];
	[iPoint setSemitone:semitone];
	[iPoint setSlope:slope];

	[self addIntonationPoint:iPoint];

	return self;
}

- addIntonationPoint: iPoint
{
double time;
int i;

	if ([iPoint ruleIndex]>currentRule)
		return self;
	[intonationPoints removeObject:iPoint];
	time = [iPoint absoluteTime];
	for (i = 0; i<[intonationPoints count];i++)
	{
		if (time<[[intonationPoints objectAt: i] absoluteTime])
		{
			[intonationPoints insertObject: iPoint at:i];
			return self;
		}
	}

	[intonationPoints addObject:iPoint];
	return self;
}


@end


