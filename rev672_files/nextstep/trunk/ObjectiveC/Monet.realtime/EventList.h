
#import <objc/Object.h>
#import <objc/List.h>
#import "Event.h"

/*===========================================================================

	Author: Craig-Richard Taube-Schock
		Copyright (c) 1994, Trillium Sound Research Incorporated.
		All Rights Reserved.

=============================================================================
*/

#define MAXPHONES	1500
#define MAXFEET		110
#define MAXTONEGROUPS	50

#define MAXRULES	MAXPHONES-1

#define STATEMENT	0
#define EXCLAIMATION	1
#define QUESTION	2
#define CONTINUATION	3
#define SEMICOLON	4

struct _phone {
	id	phone;
	int	syllable;
	double	onset;
	float	ruleTempo;
};

struct _foot {
	double	onset1;
	double	onset2;
	double	tempo;
	int	start;
	int	end;
	int	marked;
	int	last;
};

struct _toneGroup {
	int	startFoot;
	int	endFoot;
	int	type;
};

struct _rule {
	int 	number;
	int	firstPhone;
	int	lastPhone;
	double	duration;
	double	beat;
};


@interface EventList:List
{
	int	zeroRef;
	int	zeroIndex;
	int	duration;
	int	timeQuantization;
	int	parameterStore;
	int	softwareSynthesis;
	int	macroFlag;
	int	microFlag;
	int	driftFlag;
	int	smoothIntonation;

	double	radiusMultiply;
	double 	pitchMean;
	double	globalTempo;
	double	multiplier;
	float	*intonParms;

	/* NOTE phones and phoneTempo are separate for Optimization reasons */
	struct _phone phones[MAXPHONES];
	double phoneTempo[MAXPHONES];

	struct _foot feet[MAXFEET];
	struct _toneGroup toneGroups[MAXTONEGROUPS];

	struct _rule rules[MAXRULES];

	int	currentPhone;
	int	currentFoot;
	int	currentToneGroup;

	int	currentRule;

	int	cache;
	double min[16], max[16];

	List	*intonationPoints;
}

- init;
- initCount:(unsigned int)numSlots;
- free;

- setUp;

- setZeroRef: (int) newValue;
-(int) zeroRef;

- setRadiusMultiply: (double) newValue;
- (double) radiusMultiply;

- setDuration: (int) newValue;
-(int) duration;

- setFullTimeScale;

- setTimeQuantization:(int) newValue;
-(int) timeQuantization;

- setParameterStore: (int) newValue;
-(int) parameterStore;

- setSoftwareSynthesis: (int) newValue;
- (int) softwareSynthesis;

- setPitchMean:(double) newMean;
-(double) pitchMean;

- setGlobalTempo:(double) newTempo;
-(double) globalTempo;
- setMultiplier:(double) newValue;
-(double) multiplier;

- setMacroIntonation: (int) newValue;
-(int) macroIntonation;

- setMicroIntonation: (int) newValue;
-(int) microIntonation;

- setDrift: (int) newValue;
-(int) drift;

- setSmoothIntonation: (int) newValue;
-(int) smoothIntonation;

- setIntonParms: (float *) newValue;
-(float *) intonParms;

- getPhoneAtIndex:(int) phoneIndex;
- (struct _rule *) getRuleAtIndex: (int) ruleIndex;
- (double) getBeatAtIndex:(int) ruleIndex;
- (int) numberOfRules;

/* Data structure maintenance stuff */
- newToneGroup;
- setCurrentToneGroupType: (int) type;

- newFoot;
- setCurrentFootMarked;
- setCurrentFootLast;
- setCurrentFootTempo:(double) tempo;

- newPhone;
- newPhoneWithObject: anObject;
- replaceCurrentPhoneWith:anObject;
- setCurrentPhoneTempo:(double) tempo;
- setCurrentPhoneRuleTempo:(float) tempo;
- setCurrentPhoneSyllable;

- printDataStructures;

- insertEvent:(int) number atTime: (double) time withValue: (double) value;
- finalEvent:(int) number withValue: (double) value;
- lastEvent;

- generateEventList;
- generateOutput;
- synthesizeToFile: (const char *) filename;

- applyRule: rule withPhones: phoneList andTempos: (double *) tempos phoneIndex: (int) phoneIndex ;

- applyIntonation;
- applyIntonationSmooth;

- addPoint:(double) semitone offsetTime:(double) offsetTime slope:(double) slope ruleIndex:(int)ruleIndex eventList: anEventList;
- addIntonationPoint: iPoint;

@end
