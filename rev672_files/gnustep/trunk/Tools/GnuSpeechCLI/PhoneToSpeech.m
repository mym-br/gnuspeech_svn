//
//  PhoneToSpeech.m
//  (from GnuTTSServer)
//
//  Created by Dalmazio on 05/01/09.
//  Copyright 2009 Dalmazio Brisinda. All rights reserved.
//
//  Modified by mymatuda
//

#import "PhoneToSpeech.h"

#import <GnuSpeech/GnuSpeech.h>

#import "config.h"



@implementation PhoneToSpeech

- (id)initWithConfiguration:(NSDictionary*)aConfiguration
{
	[super init];

	configuration = [aConfiguration retain];
	eventList = [[EventList alloc] init];
	synthesizer = [[TRMSynthesizer alloc] init];

	NSString* articPath = [[NSBundle mainBundle] pathForResource:[configuration objectForKey:CFG_KEY_ARTICULATION_DATA] ofType:@"mxml"];
	if (articPath == nil) {
		[NSException raise:NSGenericException format:@"Could not obtain the path of the articulation data."];
	}

	// Load the Model.
	MDocument *document = [[MDocument alloc] init];
	BOOL result = [document loadFromXMLFile:articPath];
	if (result == YES) {
		model = [[document model] retain];
		[eventList setModel:model];
	} else {
		[NSException raise:NSGenericException format:@"Could not load the model."];
	}
	[document release];

	return self;
}

- (void)dealloc
{
	[model release];
	[synthesizer release];
	[eventList release];
	[configuration release];

	[super dealloc];
}

- (void)prepareForSynthesis
{
	MMSynthesisParameters *synthParameters = [model synthesisParameters];
	[synthParameters setMasterVolume:    [[configuration objectForKey:MDK_MASTER_VOLUME     ] doubleValue]];
	[synthParameters setVocalTractLength:[[configuration objectForKey:MDK_VOCAL_TRACT_LENGTH] doubleValue]];
	[synthParameters setTemperature:     [[configuration objectForKey:MDK_TEMPERATURE       ] doubleValue]];
	[synthParameters setBalance:         [[configuration objectForKey:MDK_BALANCE           ] doubleValue]];
	[synthParameters setBreathiness:     [[configuration objectForKey:MDK_BREATHINESS       ] doubleValue]];
	[synthParameters setLossFactor:      [[configuration objectForKey:MDK_LOSS_FACTOR       ] doubleValue]];
	[synthParameters setPitch:           [[configuration objectForKey:MDK_PITCH             ] doubleValue]];
	[synthParameters setThroatCutoff:    [[configuration objectForKey:MDK_THROAT_CUTTOFF    ] doubleValue]];
	[synthParameters setThroatVolume:    [[configuration objectForKey:MDK_THROAT_VOLUME     ] doubleValue]];
	[synthParameters setApertureScaling: [[configuration objectForKey:MDK_APERTURE_SCALING  ] doubleValue]];
	[synthParameters setMouthCoef:       [[configuration objectForKey:MDK_MOUTH_COEF        ] doubleValue]];
	[synthParameters setNoseCoef:        [[configuration objectForKey:MDK_NOSE_COEF         ] doubleValue]];
	[synthParameters setMixOffset:       [[configuration objectForKey:MDK_MIX_OFFSET        ] doubleValue]];
	[synthParameters setN1:              [[configuration objectForKey:MDK_N1                ] doubleValue]];
	[synthParameters setN2:              [[configuration objectForKey:MDK_N2                ] doubleValue]];
	[synthParameters setN3:              [[configuration objectForKey:MDK_N3                ] doubleValue]];
	[synthParameters setN4:              [[configuration objectForKey:MDK_N4                ] doubleValue]];
	[synthParameters setN5:              [[configuration objectForKey:MDK_N5                ] doubleValue]];
	[synthParameters setTp:              [[configuration objectForKey:MDK_TP                ] doubleValue]];
	[synthParameters setTnMin:           [[configuration objectForKey:MDK_TN_MIN            ] doubleValue]];
	[synthParameters setTnMax:           [[configuration objectForKey:MDK_TN_MAX            ] doubleValue]];
	[synthParameters setShouldUseNoiseModulation:[[configuration objectForKey:MDK_NOISE_MODULATION] boolValue]];
	[synthParameters setGlottalPulseShape:[MMSynthesisParameters glottalPulseShapeFromString:[configuration objectForKey:MDK_GP_SHAPE       ]]];
	[synthParameters setSamplingRate:     [MMSynthesisParameters      samplingRateFromString:[configuration objectForKey:MDK_SAMPLING_RATE  ]]];
	[synthParameters setOutputChannels:   [MMSynthesisParameters          channelsFromString:[configuration objectForKey:MDK_OUTPUT_CHANNELS]]];

	[eventList setUp];

	[synthesizer setShouldSaveToSoundFile:YES];
	[synthesizer setFileType:2]; // WAV
	[synthesizer setFilename:[configuration objectForKey:CFG_KEY_OUTPUT_FILE]];

	[eventList setPitchMean:[synthParameters pitch]];
	[eventList setGlobalTempo:[[configuration objectForKey:CFG_KEY_GLOBAL_TEMPO] doubleValue]];
	[eventList setShouldStoreParameters:NO];

	[eventList setShouldUseMacroIntonation:[[configuration objectForKey:CFG_KEY_SHOULD_USE_MACRO_INTONATION] boolValue]];
	[eventList setShouldUseMicroIntonation:[[configuration objectForKey:CFG_KEY_SHOULD_USE_MICRO_INTONATION] boolValue]];
	[eventList setShouldUseDrift:          [[configuration objectForKey:CFG_KEY_SHOULD_USE_DRIFT           ] boolValue]];
	setDriftGenerator([[configuration objectForKey:CFG_KEY_DRIFT_GENERATOR_DEVIATION     ] floatValue],
	                  [[configuration objectForKey:CFG_KEY_DRIFT_GENERATOR_SAMPLERATE    ] floatValue],
	                  [[configuration objectForKey:CFG_KEY_DRIFT_GENERATOR_LOWPASS_CUTOFF] floatValue]);

	[eventList setRadiusMultiply:[[configuration objectForKey:CFG_KEY_RADIUS_MULTIPLY] doubleValue]];

	intonationParameters.notionalPitch = [[configuration objectForKey:CFG_KEY_INTONATION_NOTIONAL_PITCH] doubleValue];
	intonationParameters.pretonicRange = [[configuration objectForKey:CFG_KEY_INTONATION_PRETONIC_RANGE] doubleValue];
	intonationParameters.pretonicLift  = [[configuration objectForKey:CFG_KEY_INTONATION_PRETONIC_LIFT ] doubleValue];
	intonationParameters.tonicRange    = [[configuration objectForKey:CFG_KEY_INTONATION_TONIC_RANGE   ] doubleValue];
	intonationParameters.tonicMovement = [[configuration objectForKey:CFG_KEY_INTONATION_TONIC_MOVEMENT] doubleValue];
	[eventList setIntonationParameters:intonationParameters];
}

- (void)continueSynthesis
{
	[eventList setShouldUseSmoothIntonation:[[configuration objectForKey:CFG_KEY_SHOULD_USE_SMOOTH_INTONATION] boolValue]];
	[eventList applyIntonation];

	[synthesizer setupSynthesisParameters:[model synthesisParameters]];
	[synthesizer removeAllParameters];

	[eventList setDelegate:synthesizer];
	[eventList generateOutput];
	[eventList setDelegate:nil];

	[synthesizer synthesize];
}

- (void)synthesize:(NSString*)phoneString
{
	[self prepareForSynthesis];

	[eventList parsePhoneString:phoneString];  // this creates the tone groups, feet, etc.
	[eventList applyRhythm];
	[eventList applyRules];  // this applies the rules, adding events to the EventList
	[eventList generateIntonationPoints];

	[self continueSynthesis];
}

- (void)speakPhoneString:(NSString*)phoneString
{
	[self synthesize:phoneString];
}

@end
