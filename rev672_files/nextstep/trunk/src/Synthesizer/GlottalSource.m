/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/GlottalSource.m,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

# Revision 1.1.1.1  1994/05/20  00:21:40  len
# Initial archive of TRM interactive Synthesizer.
#

******************************************************************************/

/*  HEADER FILES  ************************************************************/
#import "GlottalSource.h"
#import "ScaleView.h"
#import "ParameterView.h"
#import "WaveshapeView.h"
#import "HarmonicsView.h"
#import "NoiseSource.h"
#import "Synthesizer.h"
#import "Controller.h"
#import "conversion.h"
#import "dsp_control.h"
#include <math.h>



/*  LOCAL DEFINES  ***********************************************************/
#define BREATHINESS_MIN   0.0
#define BREATHINESS_MAX   10.0
#define BREATHINESS_DEF   2.5

#define PITCH_MIN         (-24)
#define PITCH_MAX         24
#define PITCH_DEF         0

#define CENTS_MIN         (-50)
#define CENTS_MAX         50
#define CENTS_DEF         0

#define UNIT_SEMITONES    0
#define UNIT_CENTS        1
#define UNIT_DEF          UNIT_SEMITONES

#define WAVEFORMTYPE_DEF  WAVEFORMTYPE_GP

#define SHOWAMPLITUDE_DEF YES

#define HARMONICS_LIN     0
#define HARMONICS_LOG     1
#define HARMONICS_DEF     HARMONICS_LOG

#define RISETIME_MIN      5.0
#define RISETIME_MAX      50.0
#define RISETIME_DEF      40.0

#define FALLTIMEMIN_MIN   5.0
#define FALLTIMEMIN_MAX   50.0
#define FALLTIMEMIN_DEF   12.0

#if VARIABLE_GP
#define FALLTIMEMAX_MIN   5.0
#define FALLTIMEMAX_MAX   50.0
#define FALLTIMEMAX_DEF   35.0
#else  // is really top harmonic
#define FALLTIMEMAX_MIN   1
#define FALLTIMEMAX_MAX   (GP_TABLE_SIZE/2)
#define FALLTIMEMAX_DEF   25
#endif




@implementation GlottalSource

- init
{
    /*  DO REGULAR INITIALIZATION  */
    [super init];

    /*  SET INSTANCE VARIABLES TO DEFAULT VALUES  */
    [self defaultInstanceVariables];

    return self;
}



- (void)defaultInstanceVariables
{
    /*  SET INSTANCE VARIABLES TO DEFAULTS  */
    pitch = PITCH_DEF;
    cents = CENTS_DEF;
    unit = UNIT_DEF;
    breathiness = BREATHINESS_DEF;
    volume = VOLUME_DEF;
    waveformType = WAVEFORMTYPE_DEF;
    showAmplitude = SHOWAMPLITUDE_DEF;
    harmonicsScale = HARMONICS_DEF;
    riseTime = RISETIME_DEF;
    fallTimeMin = FALLTIMEMIN_DEF;
    fallTimeMax = FALLTIMEMAX_DEF; 
}



- (void)awakeFromNib
{
    /*  USE OPTIMIZED DRAWING IN THE WINDOW  */
    [glottalSourceWindow useOptimizedDrawing:YES];

    /*  SAVE THE FRAME FOR THE WINDOW  */
    [glottalSourceWindow setFrameAutosaveName:@"glottalSourceWindow"];

    /*  SET FORM FORMATS  */
    [frequencyField setFloatingPointFormat:NO left:4 right:2];
    [pitchField setFloatingPointFormat:NO left:3 right:2];
    [pitchMaxField setFloatingPointFormat:NO left:4 right:2];
    [pitchMinField setFloatingPointFormat:NO left:4 right:2];
    [breathinessField setFloatingPointFormat:NO left:1 right:1];
    [[parameterForm cellAtRow:0 column:0] setFloatingPointFormat:NO left:2 right:1];
    [[parameterForm cellAtRow:1 column:0] setFloatingPointFormat:NO left:2 right:1];
    #if VARIABLE_GP
    [[parameterForm cellAtRow:2 column:0] setFloatingPointFormat:NO left:2 right:1];
    #else
    [[parameterForm cellAtRow:2 column:0] setFloatingPointFormat:NO left:2 right:0];
    #endif

    /*  RENAME LABELS IF STATIC GLOTTAL PULSE  */
    #if !VARIABLE_GP
    [parameterForm setTitle:@"Fall Time:" atIndex:1];
    [parameterForm setTitle:@"Top Harmonic:" atIndex:2];
    [[parameterPercent cellAtRow:2 column:0] setStringValue:@""];
    #endif

    /*  SET SLIDER MIN AND MAX VALUES  */
    [breathinessSlider setMinValue:BREATHINESS_MIN];
    [breathinessSlider setMaxValue:BREATHINESS_MAX];
    [volumeSlider setMinValue:VOLUME_MIN];
    [volumeSlider setMaxValue:VOLUME_MAX];
}



- (void)displayAndSynthesizeIvars
{
    
    /*  INITIALIZE PARAMETER FIELDS  */
    [[parameterForm cellAtRow:0 column:0] setFloatValue:riseTime];
    [[parameterForm cellAtRow:1 column:0] setFloatValue:fallTimeMin];
    #if VARIABLE_GP
    [[parameterForm cellAtRow:2 column:0] setFloatValue:fallTimeMax];
    #else
    [[parameterForm cellAtRow:2 column:0] setIntValue:(int)fallTimeMax];
    #endif

    /*  DRAW PARAMETER VIEW  */
    #if VARIABLE_GP
    [parameterView drawRiseTime:riseTime fallTimeMin:fallTimeMin fallTimeMax:fallTimeMax];
    #else
    [parameterView drawRiseTime:riseTime fallTimeMin:fallTimeMin fallTimeMax:fallTimeMin];
    #endif

    /*  SEND GLOTTAL PARAMETERS TO SYNTHESIZER  */
    [synthesizer setRiseTime:riseTime fallTimeMin:fallTimeMin fallTimeMax:fallTimeMax];

    /*  INITIALIZE SHOW AMPLITUDE SWITCH  */
    [showAmplitudeSwitch setIntValue:showAmplitude];

    /*  INITIALIZE HARMONICS SWITCH  */
    [harmonicsSwitch selectCellWithTag:harmonicsScale];
    
    /*  INITIALIZE WAVEFORM TYPE SWITCH  */
    [waveformTypeSwitch selectCellWithTag:waveformType];
    
    /*  SEND WAVEFORM PARAMETER TO THE SYNTHESIZER  */
    [synthesizer setWaveformType:waveformType];

    /*  IF SINE TONE, DISABLE THE PARAMETER FORM, OTHERWISE ENABLE IT  */
    if (waveformType == WAVEFORMTYPE_SINE) {
	[parameterForm setEnabled:NO];
	[[parameterPercent cellAtRow:0 column:0] setTextColor:[NSColor darkGrayColor]];
	[[parameterPercent cellAtRow:1 column:0] setTextColor:[NSColor darkGrayColor]];
	[[parameterPercent cellAtRow:2 column:0] setTextColor:[NSColor darkGrayColor]];
    }
    else {
	[parameterForm setEnabled:YES];
	[[parameterPercent cellAtRow:0 column:0] setTextColor:[NSColor blackColor]];
	[[parameterPercent cellAtRow:1 column:0] setTextColor:[NSColor blackColor]];
	[[parameterPercent cellAtRow:2 column:0] setTextColor:[NSColor blackColor]];
    }

    /*  INITIALIZE BREATHINESS OBJECTS  */
    [breathinessSlider setFloatValue:breathiness];
    [breathinessField setFloatValue:breathiness];
    [synthesizer setBreathiness:breathiness];
    
    /*  INITIALIZE VOLUME OBJECTS  */
    [volumeSlider setIntValue:volume];
    [volumeField setIntValue:volume];
    [synthesizer setSourceVolume:volume];


    /*  INTIALIZE PITCH OBJECTS  */
    [unitButton setState:unit];
    [self unitButtonPushed:unitButton];
    [synthesizer setPitch:normalizedPitch(pitch,cents)];

    /*  DISPLAY NOTE IN SCALE  */
    [scaleView drawPitch:pitch Cents:cents Volume:volume];

    /*  DISPLAY WAVEFORM AND HARMONICS  */
    [self displayWaveformAndHarmonics];
    
    /*  DISPLAY CHANGES TO SUBVIEWS OF WINDOW  */
    [glottalSourceWindow displayIfNeeded]; 
}



- (void)saveToStream:(NSArchiver *)typedStream
{
    /*  WRITE INSTANCE VARIABLES TO TYPED STREAM  */
    [typedStream encodeValuesOfObjCTypes:"iiiiiififff", &waveformType, &showAmplitude,
		 &harmonicsScale, &unit, &pitch, &cents, &breathiness,
		 &volume, &riseTime, &fallTimeMin, &fallTimeMax]; 
}



- (void)openFromStream:(NSArchiver *)typedStream
{
    /*  READ INSTANCE VARIABLES FROM TYPED STREAM  */
    [typedStream decodeValuesOfObjCTypes:"iiiiiififff", &waveformType, &showAmplitude,
		&harmonicsScale, &unit, &pitch, &cents, &breathiness,
		&volume, &riseTime, &fallTimeMin, &fallTimeMax];

    /*  DISPLAY THE NEW VALUES  */
    [self displayAndSynthesizeIvars]; 
}

#ifdef NeXT
- (void)_openFromStream:(NXTypedStream *)typedStream
{
    /*  READ INSTANCE VARIABLES FROM TYPED STREAM  */
    NXReadTypes(typedStream, "iiiiiififff", &waveformType, &showAmplitude,
		&harmonicsScale, &unit, &pitch, &cents, &breathiness,
		&volume, &riseTime, &fallTimeMin, &fallTimeMax);

    /*  DISPLAY THE NEW VALUES  */
    [self displayAndSynthesizeIvars]; 
}
#endif



- (void)breathinessEntered:sender
{
    BOOL rangeError = NO;

    /*  GET CURRENT VALUE FROM FIELD  */
    float currentValue = [sender floatValue];

    /*  CORRECT OUT OF RANGE VALUES  */
    if (currentValue < BREATHINESS_MIN) {
	rangeError = YES;
	currentValue = BREATHINESS_MIN;
    }
    else if (currentValue > BREATHINESS_MAX) {
	rangeError = YES;
	currentValue = BREATHINESS_MAX;
    }

    /*  IF CURRENT VALUE IS DIFFERENT FROM PREVIOUS VALUE, DEAL WITH IT  */
    if (currentValue != breathiness) {
	/*  SET INSTANCE VARIABLE  */
	breathiness = currentValue;
	
	/*  SET SLIDER TO NEW VALUE  */
	[breathinessSlider setFloatValue:breathiness];

	/*  SEND BREATHINESS TO SYNTHESIZER  */
	[synthesizer setBreathiness:breathiness];

	/*  SET DIRTY BIT  */
	[controller setDirtyBit];
    }

    /*  BEEP AND HIGHLIGHT FIELD IF RANGE ERROR  */
    if (rangeError) {
	NSBeep();
	[sender setFloatValue:currentValue];
	[sender selectText:self];
    } 
}



- (void)breathinessSliderMoved:sender
{
    float currentValue;
    
    /*  SET FIELD TO VALUE  */
    [breathinessField setFloatValue:[sender floatValue]];

    /*  GET QUANTIZED VALUE (FROM FIELD)  */
    currentValue = [breathinessField floatValue];

    /*  ADJUST SOUND IF VALUE IS DIFFERENT FROM OLD VALUE  */
    if (currentValue != breathiness) {
	/*  SET BREATHINESS  */
	breathiness = currentValue;
	
	/*  SEND VALUE TO SYNTHESIZER  */
	[synthesizer setBreathiness:breathiness];

	/*  SET DIRTY BIT  */
	[controller setDirtyBit];
    } 
}



- (void)waveformTypeSwitchPushed:sender
{
    /*  GET THE WAVEFORM TYPE  */
    int selectedType = [[sender selectedCell] tag];
    
    /*  DEAL WITH SELECTION ONLY IF IT DIFFERS FROM PREVIOUS CHOICE  */
    if (selectedType != waveformType) {
	/* SET THE WAVEFORM TYPE  */
	waveformType = selectedType;
	
	/*  DISPLAY WAVEFORM AND HARMONICS  */
	[self displayWaveformAndHarmonics];
	
	/*  IF SINE TONE, DISABLE THE PARAMETER FORM, OTHERWISE ENABLE IT  */
	if (waveformType == WAVEFORMTYPE_SINE) {
	    [parameterForm setEnabled:NO];
	    [[parameterPercent cellAtRow:0 column:0] setTextColor:[NSColor darkGrayColor]];
	    [[parameterPercent cellAtRow:1 column:0] setTextColor:[NSColor darkGrayColor]];
	    [[parameterPercent cellAtRow:2 column:0] setTextColor:[NSColor darkGrayColor]];
	}
	else {
	    [parameterForm setEnabled:YES];
	    [[parameterPercent cellAtRow:0 column:0] setTextColor:[NSColor blackColor]];
	    [[parameterPercent cellAtRow:1 column:0] setTextColor:[NSColor blackColor]];
	    [[parameterPercent cellAtRow:2 column:0] setTextColor:[NSColor blackColor]];
	}
	
	/*  DISPLAY CHANGES TO SUBVIEWS OF WINDOW  */
	[glottalSourceWindow displayIfNeeded];
	
	/*  SEND PARAMETER TO THE SYNTHESIZER  */
	[synthesizer setWaveformType:waveformType];

	/*  SET DIRTY BIT  */
	[controller setDirtyBit];
    } 
}



- (void)riseTimeEntered:sender
{
    /*  GET QUANTIZED VALUE */
    riseTime = [sender floatValue];

    /*  MAKE SURE VALUE IS IN RANGE  */
    if (riseTime < RISETIME_MIN) {
	NSBeep();
	riseTime = RISETIME_MIN;
	[sender setFloatValue:riseTime];
	/*  SELECT THE CURRENT PARAMETER FIELD  */
	[parameterForm selectTextAtRow:0 column:0];
    }
    else if (riseTime > RISETIME_MAX) {
	NSBeep();
	riseTime = RISETIME_MAX;
	[sender setFloatValue:riseTime];
	/*  SELECT THE CURRENT PARAMETER FIELD  */
	[parameterForm selectTextAtRow:0 column:0];
    }
    else {
	/*  SELECT THE NEXT PARAMETER FIELD  */
	[parameterForm selectTextAtRow:1 column:0];
    }

    /*  REDISPLAY THE PARAMETER VIEW  */
    #if VARIABLE_GP
    [parameterView drawRiseTime:riseTime fallTimeMin:fallTimeMin fallTimeMax:fallTimeMax];
    #else
    [parameterView drawRiseTime:riseTime fallTimeMin:fallTimeMin fallTimeMax:fallTimeMin];
    #endif

    /*  DISPLAY WAVEFORM AND HARMONICS  */
    [self displayWaveformAndHarmonics];

    /*  SEND GLOTTAL PARAMETERS TO SYNTHESIZER  */
    [synthesizer setRiseTime:riseTime fallTimeMin:fallTimeMin fallTimeMax:fallTimeMax];
    
    /*  SET DIRTY BIT  */
    [controller setDirtyBit]; 
}



- (void)fallTimeMinEntered:sender
{
    /*  GET QUANTIZED VALUE */
    fallTimeMin = [sender floatValue];

    /*  MAKE SURE VALUE IS IN RANGE  */
    if (fallTimeMin < FALLTIMEMIN_MIN) {
	NSBeep();
	fallTimeMin = FALLTIMEMIN_MIN;
	[sender setFloatValue:fallTimeMin];
	/*  SELECT THE CURRENT PARAMETER FIELD  */
	[parameterForm selectTextAtRow:1 column:0];
    }
    else if (fallTimeMin > FALLTIMEMIN_MAX) {
	NSBeep();
	fallTimeMin = FALLTIMEMIN_MAX;
	[sender setFloatValue:fallTimeMin];
	/*  SELECT THE CURRENT PARAMETER FIELD  */
	[parameterForm selectTextAtRow:1 column:0];
    }
    else {
	/*  SELECT THE NEXT PARAMETER FIELD  */
	[parameterForm selectTextAtRow:2 column:0];
    }

    /*  REDISPLAY THE PARAMETER VIEW  */
    #if VARIABLE_GP
    [parameterView drawRiseTime:riseTime fallTimeMin:fallTimeMin fallTimeMax:fallTimeMax];
    #else
    [parameterView drawRiseTime:riseTime fallTimeMin:fallTimeMin fallTimeMax:fallTimeMin];
    #endif

    /*  DISPLAY WAVEFORM AND HARMONICS  */
    [self displayWaveformAndHarmonics];

    /*  SEND GLOTTAL PARAMETERS TO SYNTHESIZER  */
    [synthesizer setRiseTime:riseTime fallTimeMin:fallTimeMin fallTimeMax:fallTimeMax];
    
    /*  SET DIRTY BIT  */
    [controller setDirtyBit]; 
}



- (void)fallTimeMaxEntered:sender
{
    /*  GET QUANTIZED VALUE */
    #if VARIABLE_GP
    fallTimeMax = [sender floatValue];
    #else
    fallTimeMax = (float)[sender intValue];
    #endif

    /*  MAKE SURE VALUE IS IN RANGE  */
    if (fallTimeMax < FALLTIMEMAX_MIN) {
	NSBeep();
	fallTimeMax = FALLTIMEMAX_MIN;
	#if VARIABLE_GP
	[sender setFloatValue:fallTimeMax];
	#else
	[sender setIntValue:(int)fallTimeMax];
	#endif
	/*  SELECT THE CURRENT PARAMETER FIELD  */
	[parameterForm selectTextAtRow:2 column:0];
    }
    else if (fallTimeMax > FALLTIMEMAX_MAX) {
	NSBeep();
	fallTimeMax = FALLTIMEMAX_MAX;
	#if VARIABLE_GP
	[sender setFloatValue:fallTimeMax];
	#else
	[sender setIntValue:(int)fallTimeMax];
	#endif
	/*  SELECT THE CURRENT PARAMETER FIELD  */
	[parameterForm selectTextAtRow:2 column:0];
    }
    else {
	/*  SELECT THE NEXT PARAMETER FIELD  */
	[parameterForm selectTextAtRow:0 column:0];
    }

    /*  REDISPLAY THE PARAMETER VIEW  */
    #if VARIABLE_GP
    [parameterView drawRiseTime:riseTime fallTimeMin:fallTimeMin fallTimeMax:fallTimeMax];
    #else
    [parameterView drawRiseTime:riseTime fallTimeMin:fallTimeMin fallTimeMax:fallTimeMin];
    #endif

    /*  DISPLAY WAVEFORM AND HARMONICS  */
    [self displayWaveformAndHarmonics];

    /*  SEND GLOTTAL PARAMETERS TO SYNTHESIZER  */
    [synthesizer setRiseTime:riseTime fallTimeMin:fallTimeMin fallTimeMax:fallTimeMax];
    
    /*  SET DIRTY BIT  */
    [controller setDirtyBit]; 
}



- (void)frequencyEntered:sender
{
    BOOL rangeError = NO;

    /*  CONVERT FREQUENCY TO PITCH  */
    double currentPitch = Pitch([sender doubleValue]);
    
    /*  CORRECT OUT OF RANGE VALUES  */
    if (currentPitch < normalizedPitch(PITCH_MIN,CENTS_MIN)) {
	rangeError = YES;
	currentPitch = normalizedPitch(PITCH_MIN,CENTS_MIN);
    }
    else if (currentPitch > normalizedPitch(PITCH_MAX,CENTS_MAX)) {
	rangeError = YES;
	currentPitch = normalizedPitch(PITCH_MAX,CENTS_MAX);
    }

    /*  SET FREQUENCY TO NEAREST PITCH+CENTS VALUE  */
    [sender setDoubleValue:frequency(currentPitch)];
    
    /*  SET THE VALUE OF THE PITCH FIELD (AND SLIDER, ETC.)  */
    [pitchField setFloatValue:currentPitch];
    [self pitchEntered:pitchField];

    /*  BEEP AND SELECT FIELD, IF RANGE ERROR  */
    if (rangeError) {
	NSBeep();
	[sender selectText:self];
    } 
}



- (void)pitchEntered:sender
{
    /*  GET CURRENT VALUE FROM FIELD  */
    float currentValue = [sender floatValue];

    /*  CORRECT OUT OF RANGE VALUES  */
    if (currentValue < normalizedPitch(PITCH_MIN,CENTS_MIN)) {
	NSBeep();
	currentValue = normalizedPitch(PITCH_MIN,CENTS_MIN);
	[sender setFloatValue:currentValue];
	[sender selectText:self];
    }
    else if (currentValue > normalizedPitch(PITCH_MAX,CENTS_MAX)) {
	NSBeep();
	currentValue = normalizedPitch(PITCH_MAX,CENTS_MAX);
	[sender setFloatValue:currentValue];
	[sender selectText:self];
    }

    /*  GET THE PITCH AND CENTS VALUES  */
    pitch = (int)currentValue;
    cents = (int)rint((currentValue - (int)currentValue) * 100);

    /*  ADJUST PITCH AND CENTS IF CENTS ARE OUT OF RANGE  */
    if (cents > CENTS_MAX) {
	pitch += 1;
	cents -= 100;
    }
    if (cents < CENTS_MIN) {
	pitch -= 1;
	cents += 100;
    }


    /*  SET THE SLIDER TO THE VALUE  */
    if (unit == UNIT_SEMITONES) {
	/*  RESET PITCH MINIMUM & MAXIMUM FIELDS  */
	[pitchMaxField setFloatValue:normalizedPitch(PITCH_MAX,cents)];
	[pitchMinField setFloatValue:normalizedPitch(PITCH_MIN,cents)];

	/*  RESET SLIDER MINIMUM AND MAXIMUM VALUES  */
	[pitchSlider setMaxValue:PITCH_MAX];
	[pitchSlider setMinValue:PITCH_MIN];

	/*  RESET THE PITCH SLIDER TO APPROPRIATE VALUE  */
	[pitchSlider setIntValue:pitch];

	/*  DISPLAY THE NEW POSITION OF THE SLIDER  */
	[pitchSlider displayIfNeeded];
	
    }
    else {
	/*  RESET PITCH MINIMUM & MAXIMUM FIELDS  */
	[pitchMaxField setFloatValue:normalizedPitch(pitch,CENTS_MAX)];
	[pitchMinField setFloatValue:normalizedPitch(pitch,CENTS_MIN)];

	/*  RESET SLIDER MINIMUM AND MAXIMUM VALUES  */
	[pitchSlider setMaxValue:CENTS_MAX];
	[pitchSlider setMinValue:CENTS_MIN];

	/*  RESET THE PITCH SLIDER TO APPROPRIATE VALUE  */
	[pitchSlider setIntValue:cents];

	/*  DISPLAY THE NEW POSITION OF THE SLIDER  */
	[pitchSlider displayIfNeeded];
    }

    /*  DISPLAY THE EQUIVALENT FREQUENCY VALUE  */
    [frequencyField setDoubleValue:frequency(normalizedPitch(pitch,cents))];

    /*  DISPLAY NOTE IN SCALE  */
    [scaleView drawPitch:pitch Cents:cents Volume:volume];
    
    /*  SEND NEW VALUE TO THE SYNTHESIZER  */
    [synthesizer setPitch:normalizedPitch(pitch,cents)];
    
    /*  SET DIRTY BIT  */
    [controller setDirtyBit]; 
}



- (void)pitchSliderMoved:sender
{
    /*  GET THE CURRENT VALUE OF THE SLIDER  */
    int currentValue = [sender intValue];

    /*  RECORD THE NEW PITCH VALUE, AND SEND TO SYNTHESIZER IF CHANGED  */
    if (unit == UNIT_SEMITONES) {
	if (currentValue != pitch) {
	    pitch = currentValue;
	    
	    /*  DISPLAY NOTE IN SCALE  */
	    [scaleView drawPitch:pitch Cents:cents Volume:volume];
	    
	    /*  SEND NEW VALUE TO THE SYNTHESIZER  */
	    [synthesizer setPitch:normalizedPitch(pitch,cents)];

	    /*  SET DIRTY BIT  */
	    [controller setDirtyBit];
	}
    }
    else if (unit == UNIT_CENTS) {
	if (currentValue != cents) {
	    cents = currentValue;
	    
	    /*  DISPLAY NOTE IN SCALE  */
	    [scaleView drawPitch:pitch Cents:cents Volume:volume];
	    
	    /*  SEND NEW VALUE TO THE SYNTHESIZER  */
	    [synthesizer setPitch:normalizedPitch(pitch,cents)];

	    /*  SET DIRTY BIT  */
	    [controller setDirtyBit];
	}
    }
    
    /*  DISPLAY CURRENT PITCH+CENTS VALUE  */
    [pitchField setFloatValue:normalizedPitch(pitch,cents)];
    
    /*  DISPLAY THE EQUIVALENT FREQUENCY VALUE  */
    [frequencyField setDoubleValue:frequency(normalizedPitch(pitch,cents))]; 
}



- (void)showAmplitudeSwitchPushed:sender
{
    /*  SET VALUE FROM STATE OF BUTTON  */
    showAmplitude = [sender state];

    /*  DISPLAY WAVEFORM AND HARMONICS  */
    [self displayWaveformAndHarmonics];
    
    /*  SET DIRTY BIT  */
    [controller setDirtyBit]; 
}



- (void)harmonicsSwitchPushed:sender
{
    /*  GET VALUE FROM STATE OF BUTTON  */
    int selectedValue = [[sender selectedCell] tag];

    /*  PROCESS ONLY IF NEW VALUE  */
    if (selectedValue != harmonicsScale) {
	harmonicsScale = selectedValue;
	
	/*  REDISPLAY HARMONICS  */
	if (waveformType == WAVEFORMTYPE_GP)
	    #if VARIABLE_GP
	    [harmonicsView drawGlottalPulseAmplitude:amplitude((double)volume)
			   RiseTime:riseTime
			   FallTimeMin:fallTimeMin
			   FallTimeMax:fallTimeMax
			   Scale:(BOOL)harmonicsScale];
	    #else
	    [harmonicsView drawGlottalPulseAmplitude:amplitude((double)volume)
			   RiseTime:riseTime
			   FallTimeMin:fallTimeMin
			   FallTimeMax:fallTimeMin
			   Scale:(BOOL)harmonicsScale];
	    #endif
    	else if (waveformType == WAVEFORMTYPE_SINE)
	    [harmonicsView drawSineScale:(BOOL)harmonicsScale];
	
	/*  SET DIRTY BIT  */
	[controller setDirtyBit];
    } 
}



- (void)unitButtonPushed:sender
{
    unit = [sender state];

    if (unit == UNIT_SEMITONES) {
	/*  RESET PITCH MINIMUM & MAXIMUM FIELDS  */
	[pitchMaxField setFloatValue:normalizedPitch(PITCH_MAX,cents)];
	[pitchMinField setFloatValue:normalizedPitch(PITCH_MIN,cents)];

	/*  RESET PITCH SLIDER  */
	[pitchSlider setMinValue:PITCH_MIN];
	[pitchSlider setMaxValue:PITCH_MAX];
	[pitchSlider setIntValue:pitch];

	/*  DISPLAY THE NEW POSITION OF THE SLIDER  */
	[pitchSlider displayIfNeeded];
    }
    else if (unit == UNIT_CENTS) {
	/*  RESET PITCH MINIMUM & MAXIMUM FIELDS  */
	[pitchMaxField setFloatValue:normalizedPitch(pitch,CENTS_MAX)];
	[pitchMinField setFloatValue:normalizedPitch(pitch,CENTS_MIN)];

	/*  RESET PITCH SLIDER  */
	[pitchSlider setMinValue:CENTS_MIN];
	[pitchSlider setMaxValue:CENTS_MAX];
	[pitchSlider setIntValue:cents];

	/*  DISPLAY THE NEW POSITION OF THE SLIDER  */
	[pitchSlider displayIfNeeded];
    }    

    /*  RESET THE PITCH SLIDER  */
    [self pitchSliderMoved:pitchSlider]; 
}



- (void)volumeEntered:sender
{
    BOOL rangeError = NO;

    /*  GET CURRENT ROUNDED VALUE FROM FIELD  */
    int currentValue = (int)rint([sender doubleValue]);

    /*  CORRECT OUT OF RANGE VALUES  */
    if (currentValue < VOLUME_MIN) {
	rangeError = YES;
	currentValue = VOLUME_MIN;
    }
    else if (currentValue > VOLUME_MAX) {
	rangeError = YES;
	currentValue = VOLUME_MAX;
    }

    /*  SET THE FIELD TO THE ROUNDED, CORRECTED VALUE  */
    [sender setIntValue:currentValue];

    /*  IF CURRENT VALUE IS DIFFERENT FROM PREVIOUS VALUE, DEAL WITH IT  */
    if (currentValue != volume) {
	/*  SET INSTANCE VARIABLE  */
	volume = currentValue;

	/*  SET SLIDER TO NEW VALUE  */
	[volumeSlider setIntValue:volume];

	/*  SEND VOLUME TO SYNTHESIZER  */
	[synthesizer setSourceVolume:volume];
	
	/*  SET DIRTY BIT  */
	[controller setDirtyBit];
    }

    /*  BEEP AND HIGHLIGHT FIELD IF RANGE ERROR  */
    if (rangeError) {
	NSBeep();
	[sender selectText:self];
    } 
}



- (void)volumeSliderMoved:sender
{
    /*  GET CURRENT VALUE FROM SLIDER  */
    int currentValue = [sender intValue];

    /*  ADJUST SOUND AND DISPLAYS IF VALUE IS DIFFERENT FROM OLD VALUE  */
    if (currentValue != volume) {
	/*  SET VOLUME  */
	volume = currentValue;
	
	/*  SET FIELD TO VALUE  */
	[volumeField setIntValue:volume];

	/*  SEND GLOTTAL VOLUME TO SYNTHESIZER  */
	[synthesizer setSourceVolume:volume];

	/*  DISPLAY WAVEFORM AND HARMONICS  */
	[self displayWaveformAndHarmonics];

	/*  DISPLAY NOTE IN SCALE  */
	[scaleView drawPitch:pitch Cents:cents Volume:volume];
	
	/*  SET DIRTY BIT  */
	[controller setDirtyBit]; 
    } 
}



- (void)displayWaveformAndHarmonics
{
    if (waveformType == WAVEFORMTYPE_GP) {
	float ampl = amplitude((double)volume);
	if (showAmplitude)
	    #if VARIABLE_GP
	    [waveshapeView drawGlottalPulseAmplitude:ampl Scale:ampl RiseTime:riseTime FallTimeMin:fallTimeMin FallTimeMax:fallTimeMax];
	    #else
	    [waveshapeView drawGlottalPulseAmplitude:ampl Scale:ampl RiseTime:riseTime FallTimeMin:fallTimeMin FallTimeMax:fallTimeMin];
	    #endif
	else
	    #if VARIABLE_GP
	    [waveshapeView drawGlottalPulseAmplitude:ampl Scale:1.0 RiseTime:riseTime FallTimeMin:fallTimeMin FallTimeMax:fallTimeMax];
	    #else
	    [waveshapeView drawGlottalPulseAmplitude:ampl Scale:1.0 RiseTime:riseTime FallTimeMin:fallTimeMin FallTimeMax:fallTimeMin];
	    #endif
	/*  SHOW THE HARMONICS  */
	#if VARIABLE_GP
	[harmonicsView drawGlottalPulseAmplitude:ampl
		       RiseTime:riseTime
		       FallTimeMin:fallTimeMin
		       FallTimeMax:fallTimeMax
		       Scale:(BOOL)harmonicsScale];
	#else
	[harmonicsView drawGlottalPulseAmplitude:ampl
		       RiseTime:riseTime
		       FallTimeMin:fallTimeMin
		       FallTimeMax:fallTimeMin
		       Scale:(BOOL)harmonicsScale];
	#endif
    }
    else if (waveformType == WAVEFORMTYPE_SINE) {
	if (showAmplitude)
	    [waveshapeView drawSineAmplitude:amplitude((double)volume)];
	else
	    [waveshapeView drawSineAmplitude:1.0];
	/*  SHOW THE HARMONICS  */
	[harmonicsView drawSineScale:(BOOL)harmonicsScale];
    }
    
    /*  SHOW GLOTTAL VOLUME IN NOISE SOURCE WINDOW  */
    [noiseSource setGlottalVolume:self]; 
}



- (int)glottalVolume
{
    return volume;
}



- (void)windowWillMiniaturize:sender
{
    [sender setMiniwindowTitle:@"Glottis"];
    [sender setMiniwindowImage:[NSImage imageNamed:@"Synthesizer.tiff"]];
}

@end
