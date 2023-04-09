
#import <objc/Object.h>
#import "EventList.h"
#import "RuleList.h"

/*===========================================================================

	Author: Craig-Richard Taube-Schock
		Copyright (c) 1994, Trillium Sound Research Incorporated.
		All Rights Reserved.

=============================================================================
*/

@interface StringParser:Object
{
	int stringIndex;
	int cache;
	const char *parseString;
	EventList *eventList;
	List *categoryList;
	List *phoneList;

	/* Min and Max for each parameter */
	double min[16], max[16];

	id stringTextField;
	id eventListView;

/* Synthesizer Control Panel Outlets */

	/* General*/
	id	masterVolume;
	id	length;
	id	temperature;
	id	balance;
	id	breathiness;
	id	lossFactor;
	id	pitchMean;

	/* Nasal Cavity */
	id	n1;
	id	n2;
	id	n3;
	id	n4;
	id	n5;

	id	tp;
	id	tnMin;
	id	tnMax;
	id	waveform;

	id	throatCutoff;
	id	throatVolume;
	id	apScale;
	id	mouthCoef;
	id	noseCoef;
	id	mixOffset;
	id	modulation;

	id	tempoField;

	id	fileFlag;
	id	filenameField;
	id	parametersStore;
	id	intonationFlag;
	id	intonParmsField;
}

- init;
- eventList;

- parseString: (const char *) string;
- applyRule: (Rule *) rule;
- parseStringButton: sender;

@end
