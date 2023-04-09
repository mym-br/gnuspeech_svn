
#import "RealTimeController.h"
#import <streams/streams.h>
#import "PrototypeManager.h"
#import "RuleList.h"

/* For Debugging */
#import <sys/time.h>

int validPhone(char *token)
{
int dummy;

	switch(token[0])
	{
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
			return 1;

		default:
			return ([mainPhoneList binarySearchPhone:token index:&dummy]);
	}
}

@implementation RealTimeController

- initWithFile: (const char *) fileName;
{
NXTypedStream *stream = NULL;
int i;

//	printf("init synth %d\n", initialize_synthesizer_module());
	initialize_synthesizer_module();
	prototypeManager = [[PrototypeManager alloc] init];

	stream = NXOpenTypedStreamForFile(fileName, NX_READONLY);
	if (stream)
	{
		mainCategoryList = NXReadObject(stream);
		mainSymbolList = NXReadObject(stream);
		mainParameterList = NXReadObject(stream);
		mainMetaParameterList = NXReadObject(stream);
		mainPhoneList = NXReadObject(stream);

		[prototypeManager readPrototypesFrom:stream];

		ruleList = NXReadObject(stream);

		NXCloseTypedStream(stream);
		initStringParser();
	}
	eventList = [[EventList alloc] initCount: 1000];

	return self;
}

- synthesizeString: (const char *) string
{
struct timeval tp1, tp2;
struct timezone tzp;
int i, j;
float intonationParameters[5];
float silencePage[] = {0.0, 0.0, 0.0, 0.0, 5.5, 2500.0, 500.0, 0.8, 0.89, 0.99, 0.81, 0.76, 1.05, 1.23, 0.01, 0.0};

	gettimeofday(&tp1, &tzp);

//	set_utterance_rate_parameters(22050.0, 250.0,
//		60.0,       /* Master Volume */
//		1,     /* Stereo/Mono */
//		0.0,      /* Balance */
//		0,      /* WaveForm */
//		40.0,   /* tp */
//		24.0,   /* tn Min */
//		24.0,   /* tn Max */
//		0.7,
//		18.5,
//		32.0,   /* Temperature */
//		0.8,    /* Loss Factor */
//		3.05,   /* Ap scaling */
//		5000.0, 5000.0,	 /* Mouth and nose coef */
//		1.35, 1.96, 1.91,       /* n1, n2, n3 */
//		1.3, 0.73,	      /* n4, n5 */
//		1500.0, 6.0,	    /* Throat cutoff and volume */
//		1, 48.0,		/* Noise Modulation, mixOffset */
//		silencePage);

//	defaultUtteranceRateParameters();

//	[eventList setPitchMean: -10];
//	[eventList setGlobalTempo: 1.0];
//	[eventList setIntonation: 1];
//	[eventList setParameterStore: [parametersStore state]];
//	for(i = 0;i<5;i++)
//		intonationParameters[i] = [intonParmsField floatValueAt:i];
//	[eventList setIntonParms: intonationParameters];

	parse_string(eventList, string);
//	[eventList setMacroIntonation: 1];
//	[eventList setMicroIntonation: 1];
//	[eventList setDrift: 1];
//	[eventList setSmoothIntonation:1];


//	printf("EventList Count = %d\n", [eventList count]);
	[eventList generateEventList];

	[eventList applyIntonation];
	[eventList applyIntonationSmooth];

	gettimeofday(&tp2, &tzp);
//	printf("%d\n", (tp2.tv_sec*1000000 + tp2.tv_usec) - (tp1.tv_sec*1000000 + tp1.tv_usec));

//	printf("\n***\n");
//	[eventList printDataStructures];

	[eventList generateOutput];
	[eventList setUp];

	return self;

}

- setPitchMean: (double) aValue
{
	[eventList setPitchMean: aValue];
	return self;
}

- setGlobalTempo: (double) aValue
{
	[eventList setGlobalTempo: aValue];
	return self;
}

#define TTS_INTONATION_DEF		0x1f
#define TTS_INTONATION_NONE		0x00
#define TTS_INTONATION_MICRO		0x01
#define TTS_INTONATION_MACRO		0x02
#define TTS_INTONATION_DECLIN		0x04
#define TTS_INTONATION_CREAK		0x08
#define TTS_INTONATION_RANDOMIZE	0x10
#define TTS_INTONATION_ALL		0x1f

- setIntonation: (int) intonation
{
	if (!intonation)
	{
		[eventList setMicroIntonation:0];
		[eventList setMacroIntonation:0];
		[eventList setDrift:0];
		return self;
	}

	if (intonation&TTS_INTONATION_MICRO)
		[eventList setMicroIntonation:1];
	else
		[eventList setMicroIntonation:0];

	if (intonation&TTS_INTONATION_MACRO)
	{
		[eventList setMacroIntonation:1];
		[eventList setSmoothIntonation:1];
	}
	else
	{
		[eventList setMacroIntonation:0];
		[eventList setSmoothIntonation:0];
	}

	[eventList setDrift:1];

	return self;
}

- setSoftwareSynthesis: (int) newValue
{
	[eventList setSoftwareSynthesis:newValue];
	return self;
}

@end
