/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/NoiseSource.m,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

# Revision 1.2  1994/09/19  03:05:20  len
# Resectioned the TRM to 10 sections in 8 regions.  Also
# changed friction injection to be continous from sections
# 3 to 10.
#
# Revision 1.1.1.1  1994/05/20  00:21:48  len
# Initial archive of TRM interactive Synthesizer.
#

******************************************************************************/

/*  HEADER FILES  ************************************************************/
#import "NoiseSource.h"
#import "GlottalSource.h"
#import "BandpassView.h"
#import "CrossmixView.h"
#import "ResonantSystem.h"
#import "Synthesizer.h"
#import "Controller.h"
#import "dsp_control.h"
#include <math.h>


/*  LOCAL DEFINES  ***********************************************************/
#define VOLUME_MIN       0
#define VOLUME_MAX       60
#define VOLUME_DEF       0

#define POSITION_MIN     0.0
#define POSITION_MAX     7.0
#define POSITION_DEF     7.0

#define CENTER_FREQ_MIN  100
#define CENTER_FREQ_DEF  2000

#define BANDWIDTH_MIN    250
#define BANDWIDTH_DEF    1000

#define RESPONSE_LIN     0
#define RESPONSE_LOG     1
#define RESPONSE_DEF     RESPONSE_LIN

#define PULSE_MOD_DEF    YES

#define CROSSMIX_MIN     30.0
#define CROSSMIX_MAX     VOLUME_MAX
#if FIXED_CROSSMIX
#define CROSSMIX_DEF     VOLUME_MAX
#else
#define CROSSMIX_DEF     54.0
#endif


@implementation NoiseSource

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
    fricationVolume = VOLUME_DEF;
    fricationPosition = POSITION_DEF;
    aspirationVolume = VOLUME_DEF;
    centerFrequency = CENTER_FREQ_DEF;
    responseScale = RESPONSE_DEF;
    bandwidth = BANDWIDTH_DEF;
    pulseModulation = PULSE_MOD_DEF;
    crossmixOffset = CROSSMIX_DEF; 
}



- (void)awakeFromNib
{
    /*  USE OPTIMIZED DRAWING IN THE WINDOW  */
    [noiseSourceWindow useOptimizedDrawing:YES];
    
    /*  SAVE THE FRAME FOR THE WINDOW  */
    [noiseSourceWindow setFrameAutosaveName:@"noiseSourceWindow"];

    /*  SET FORM FORMATS  */
    [positionField setFloatingPointFormat:NO left:4 right:1];
    [pureField setFloatingPointFormat:NO left:1 right:2];
    [pulsedField setFloatingPointFormat:NO left:1 right:2];

    /*  SET SLIDER MIN AND MAX VALUES  */
    [fricationVolumeSlider setMinValue:VOLUME_MIN];
    [fricationVolumeSlider setMaxValue:VOLUME_MAX];
    [positionSlider setMinValue:POSITION_MIN];
    [positionSlider setMaxValue:POSITION_MAX];

    [centerFrequencySlider setMinValue:CENTER_FREQ_MIN];
    [centerFrequencySlider setMaxValue:[resonantSystem sampleRate]/2.0];

    [bandwidthSlider setMinValue:BANDWIDTH_MIN];
    [bandwidthSlider setMaxValue:[resonantSystem sampleRate]/2.0];

    [aspirationSlider setMinValue:VOLUME_MIN];
    [aspirationSlider setMaxValue:VOLUME_MAX];

    #if FIXED_CROSSMIX
    [crossmixOffsetField setEnabled:NO];
    [crossmixOffsetDB setTextColor:[NSColor darkGrayColor]];
    #endif
}



- (void)displayAndSynthesizeIvars
{
    /*  INITIALIZE FRICATION VOLUME OBJECTS  */
    [fricationVolumeSlider setIntValue:fricationVolume];
    [fricationVolumeField setIntValue:fricationVolume];
    [synthesizer setFricationVolume:fricationVolume];

    /*  INITIALIZE FRICATION POSITION OBJECTS  */
    [positionSlider setFloatValue:fricationPosition];
    [positionField setFloatValue:fricationPosition];
    [synthesizer setFricationPosition:fricationPosition];

    /*  INITIALIZE FRICATION CENTER FREQUENCY OBJECTS  */
    [centerFrequencySlider setIntValue:centerFrequency];
    [centerFrequencyField setIntValue:centerFrequency];
    [synthesizer setFricationCenterFrequency:centerFrequency];

    /*  INITIALIZE FRICATION BANDWIDTH OBJECTS  */
    [bandwidthSlider setIntValue:bandwidth];
    [bandwidthField setIntValue:bandwidth];
    [synthesizer setFricationBandwidth:bandwidth];

    /*  INITIALIZE FREQUENCY RESPONSE SCALE SWITCH  */
    [scaleSwitch selectCellWithTag:responseScale];
    
    /*  DISPLAY NEW FREQUENCY RESPONSE  */
    [bandpassView drawCenterFrequency:centerFrequency bandwidth:bandwidth sampleRate:[resonantSystem sampleRate] scale:responseScale];
    
    /*  INITIALIZE ASPIRATION VOLUME OBJECTS  */
    [aspirationSlider setIntValue:aspirationVolume];
    [aspirationField setIntValue:aspirationVolume];
    [synthesizer setAspirationVolume:aspirationVolume];

    /*  INITIALIZE PULSE MODULATION SWITCH  */
    [pulseModulationSwitch setIntValue:pulseModulation];
    [synthesizer setPulseModulation:pulseModulation];

    /*  INITIALIZE CROSSMIX OFFSET OBJECTS  */
    [crossmixOffsetField setIntValue:crossmixOffset];
    [synthesizer setCrossmixOffset:crossmixOffset];

    /*  ENABLE OR DISABLE CROSSMIX OFFSET FIELD  */
    #if !FIXED_CROSSMIX
    [crossmixOffsetField setEnabled:pulseModulation];
    if (pulseModulation)
	[crossmixOffsetDB setTextColor:[NSColor blackColor]];
    else
	[crossmixOffsetDB setTextColor:[NSColor darkGrayColor]];
    #endif

    /*  DISPLAY CHANGE IN OFFSET  */
    if (pulseModulation)
	[crossmixView drawCrossmix:crossmixOffset];
    else
	[crossmixView drawNoCrossmix];

    /*  DISPLAY GLOTTAL SOURCE VOLUME  */
    [self setGlottalVolume:glottalSource];
    
    /*  DISPLAY CHANGES TO SUBVIEWS OF WINDOW  */
    [noiseSourceWindow displayIfNeeded]; 
}



- (void)saveToStream:(NSArchiver *)typedStream
{
    /*  WRITE INSTANCE VARIABLES TO TYPED STREAM  */
    [typedStream encodeValuesOfObjCTypes:"ifiiiiii", &fricationVolume, &fricationPosition,
		 &aspirationVolume, &centerFrequency, &responseScale,
		 &bandwidth, &pulseModulation, &crossmixOffset]; 
}



- (void)openFromStream:(NSArchiver *)typedStream
{
    /*  READ INSTANCE VARIABLES FROM TYPED STREAM  */
    [typedStream decodeValuesOfObjCTypes:"ifiiiiii", &fricationVolume, &fricationPosition,
		&aspirationVolume, &centerFrequency, &responseScale,
		&bandwidth, &pulseModulation, &crossmixOffset];

    #if FIXED_CROSSMIX
    crossmixOffset = CROSSMIX_DEF;
    #endif

    /*  DISPLAY THE NEW VALUES  */
    [self displayAndSynthesizeIvars]; 
}

#ifdef NeXT
- (void)_openFromStream:(NXTypedStream *)typedStream
{
    /*  READ INSTANCE VARIABLES FROM TYPED STREAM  */
    NXReadTypes(typedStream, "ifiiiiii", &fricationVolume, &fricationPosition,
		&aspirationVolume, &centerFrequency, &responseScale,
		&bandwidth, &pulseModulation, &crossmixOffset);

    #if FIXED_CROSSMIX
    crossmixOffset = CROSSMIX_DEF;
    #endif

    /*  DISPLAY THE NEW VALUES  */
    [self displayAndSynthesizeIvars]; 
}
#endif



- (void)fricationVolumeEntered:sender
{
    BOOL rangeError = NO;

    /*  GET CURRENT VALUE FROM FIELD  */
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
    if (currentValue != fricationVolume) {
	/*  SET INSTANCE VARIABLE  */
	fricationVolume = currentValue;

	/*  SET SLIDER TO NEW VALUE  */
	[fricationVolumeSlider setIntValue:fricationVolume];

	/*  SEND FRICATION VOLUME TO SYNTHESIZER  */
	[synthesizer setFricationVolume:fricationVolume];

	/*  SET DIRTY BIT  */
	[controller setDirtyBit];
    }

    /*  BEEP AND HIGHLIGHT FIELD IF RANGE ERROR  */
    if (rangeError) {
	NSBeep();
	[sender selectText:self];
    } 
}



- (void)fricationVolumeSliderMoved:sender
{
    /*  GET CURRENT VALUE FROM SLIDER  */
    int currentValue = [sender intValue];

    /*  ADJUST SOUND IF VALUE IS DIFFERENT FROM OLD VALUE  */
    if (currentValue != fricationVolume) {
	/*  SET FRICATION VOLUME  */
	fricationVolume = currentValue;
	
	/*  SET FIELD TO VALUE  */
	[fricationVolumeField setIntValue:fricationVolume];
	
	/*  SEND PARAMETER TO THE SYNTHESIZER  */
	[synthesizer setFricationVolume:fricationVolume];

	/*  SET DIRTY BIT  */
	[controller setDirtyBit];
    } 
}



- (void)positionEntered:sender
{
    BOOL rangeError = NO;

    /*  GET CURRENT VALUE FROM FIELD  */
    float currentValue = [sender floatValue];

    /*  CORRECT OUT OF RANGE VALUES  */
    if (currentValue < POSITION_MIN) {
	rangeError = YES;
	currentValue = POSITION_MIN;
    }
    else if (currentValue > POSITION_MAX) {
	rangeError = YES;
	currentValue = POSITION_MAX;
    }

    /*  IF CURRENT VALUE IS DIFFERENT FROM PREVIOUS VALUE, DEAL WITH IT  */
    if (currentValue != fricationPosition) {
	/*  SET INSTANCE VARIABLE  */
	fricationPosition = currentValue;
	
	/*  SET SLIDER TO NEW VALUE  */
	[positionSlider setFloatValue:fricationPosition];

	/*  DISPLAY POSITION OF FRICATION IN RESONANT SYSTEM  */
	[resonantSystem injectFricationAt:fricationPosition];

	/*  SEND FRICATION POSITION TO SYNTHESIZER  */
	[synthesizer setFricationPosition:fricationPosition];

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



- (void)positionSliderMoved:sender
{
    float currentValue;
    
    /*  SET FIELD TO VALUE  */
    [positionField setFloatValue:[sender floatValue]];

    /*  GET QUANTIZED VALUE (FROM FIELD)  */
    currentValue = [positionField floatValue];

    /*  ADJUST SOUND IF VALUE IS DIFFERENT FROM OLD VALUE  */
    if (currentValue != fricationPosition) {
	/*  SET FRICATION POSITION  */
	fricationPosition = currentValue;

	/*  DISPLAY POSITION OF FRICATION IN RESONANT SYSTEM  */
	[resonantSystem injectFricationAt:fricationPosition];

	/*  SEND PARAMETER TO SYNTHESIZER  */
	[synthesizer setFricationPosition:fricationPosition];

	/*  SET DIRTY BIT  */
	[controller setDirtyBit];
    } 
}



- (float)fricationPosition
{
    return fricationPosition;
}



- (void)centerFrequencyEntered:sender
{
    BOOL rangeError = NO;

    /*  GET CURRENT ROUNDED VALUE FROM FIELD  */
    int currentValue = (int)rint([sender doubleValue]);

    /*  CORRECT OUT OF RANGE VALUES  */
    if (currentValue < CENTER_FREQ_MIN) {
	rangeError = YES;
	currentValue = CENTER_FREQ_MIN;
    }
    else if (currentValue > ([resonantSystem sampleRate] / 2.0)) {
	rangeError = YES;
	currentValue = [resonantSystem sampleRate] / 2.0;
    }

    /*  SET THE FIELD TO THE ROUNDED, CORRECTED VALUE  */
    [sender setIntValue:currentValue];

    /*  IF CURRENT VALUE IS DIFFERENT FROM PREVIOUS VALUE, DEAL WITH IT  */
    if (currentValue != centerFrequency) {
	/*  SET INSTANCE VARIABLE  */
	centerFrequency = currentValue;

	/*  SET SLIDER TO NEW VALUE  */
	[centerFrequencySlider setIntValue:centerFrequency];

	/*  DISPLAY NEW FREQUENCY RESPONSE  */
	[bandpassView drawCenterFrequency:centerFrequency bandwidth:bandwidth sampleRate:[resonantSystem sampleRate] scale:responseScale];
	
	/*  SEND CENTER FREQUENCY TO SYNTHESIZER  */
	[synthesizer setFricationCenterFrequency:centerFrequency];

	/*  SET DIRTY BIT  */
	[controller setDirtyBit];
    }

    /*  BEEP AND HIGHLIGHT FIELD IF RANGE ERROR  */
    if (rangeError) {
	NSBeep();
	[sender selectText:self];
    } 
}



- (void)centerFrequencySliderMoved:sender
{
    /*  GET CURRENT VALUE FROM SLIDER  */
    int currentValue = [sender intValue];

    /*  ADJUST SOUND IF VALUE IS DIFFERENT FROM OLD VALUE  */
    if (currentValue != centerFrequency) {
	/*  SET FRICATION CENTER FREQUENCY  */
	centerFrequency = currentValue;
	
	/*  SET FIELD TO VALUE  */
	[centerFrequencyField setIntValue:centerFrequency];
	
	/*  DISPLAY NEW FREQUENCY RESPONSE  */
	[bandpassView drawCenterFrequency:centerFrequency bandwidth:bandwidth sampleRate:[resonantSystem sampleRate] scale:responseScale];
	
	/*  SEND PARAMETER TO THE SYNTHESIZER  */
	[synthesizer setFricationCenterFrequency:centerFrequency];

	/*  SET DIRTY BIT  */
	[controller setDirtyBit];
    } 
}



- (void)bandwidthEntered:sender
{
    BOOL rangeError = NO;

    /*  GET CURRENT ROUNDED VALUE FROM FIELD  */
    int currentValue = (int)rint([sender doubleValue]);

    /*  CORRECT OUT OF RANGE VALUES  */
    if (currentValue < BANDWIDTH_MIN) {
	rangeError = YES;
	currentValue = BANDWIDTH_MIN;
    }
    else if (currentValue > ([resonantSystem sampleRate] / 2.0)) {
	rangeError = YES;
	currentValue = [resonantSystem sampleRate] / 2.0;
    }

    /*  SET THE FIELD TO THE ROUNDED, CORRECTED VALUE  */
    [sender setIntValue:currentValue];

    /*  IF CURRENT VALUE IS DIFFERENT FROM PREVIOUS VALUE, DEAL WITH IT  */
    if (currentValue != bandwidth) {
	/*  SET INSTANCE VARIABLE  */
	bandwidth = currentValue;

	/*  SET SLIDER TO NEW VALUE  */
	[bandwidthSlider setIntValue:bandwidth];

	/*  DISPLAY NEW FREQUENCY RESPONSE  */
	[bandpassView drawCenterFrequency:centerFrequency bandwidth:bandwidth sampleRate:[resonantSystem sampleRate] scale:responseScale];
	
	/*  SEND BANDWIDTH FREQUENCY TO SYNTHESIZER  */
	[synthesizer setFricationBandwidth:bandwidth];

	/*  SET DIRTY BIT  */
	[controller setDirtyBit];
    }

    /*  BEEP AND HIGHLIGHT FIELD IF RANGE ERROR  */
    if (rangeError) {
	NSBeep();
	[sender selectText:self];
    } 
}



- (void)bandwidthSliderMoved:sender
{
    /*  GET CURRENT VALUE FROM SLIDER  */
    int currentValue = [sender intValue];

    /*  ADJUST SOUND IF VALUE IS DIFFERENT FROM OLD VALUE  */
    if (currentValue != bandwidth) {
	/*  SET FRICATION BANDWIDTH  */
	bandwidth = currentValue;
	
	/*  SET FIELD TO VALUE  */
	[bandwidthField setIntValue:bandwidth];
	
	/*  DISPLAY NEW FREQUENCY RESPONSE  */
	[bandpassView drawCenterFrequency:centerFrequency bandwidth:bandwidth sampleRate:[resonantSystem sampleRate] scale:responseScale];
	
	/*  SEND PARAMETER TO THE SYNTHESIZER  */
	[synthesizer setFricationBandwidth:bandwidth];

	/*  SET DIRTY BIT  */
	[controller setDirtyBit];
    } 
}



- (void)scaleSwitchPushed:sender
{
    /*  GET VALUE FROM STATE OF BUTTON  */
    int selectedValue = [[sender selectedCell] tag];

    /*  PROCESS ONLY IF NEW VALUE  */
    if (selectedValue != responseScale) {
	responseScale = selectedValue;
	
	/*  REDISPLAY FREQUENCY RESPONSE  */
	[bandpassView drawCenterFrequency:centerFrequency bandwidth:bandwidth sampleRate:[resonantSystem sampleRate] scale:responseScale];

	/*  SET DIRTY BIT  */
	[controller setDirtyBit];
    } 
}



- (void)aspirationEntered:sender
{
    BOOL rangeError = NO;

    /*  GET CURRENT ROUNDED VALUE FROM FIELD  */
    int currentValue = (int)rint([sender doubleValue]);

    /*  MAKE SURE VALUE IS IN RANGE  */
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
    if (currentValue != aspirationVolume) {
	/*  SET INSTANCE VARIABLE  */
	aspirationVolume = currentValue;

	/*  SET SLIDER TO NEW VALUE  */
	[aspirationSlider setIntValue:aspirationVolume];

	/*  SEND ASPIRATION VOLUME TO SYNTHESIZER  */
	[synthesizer setAspirationVolume:aspirationVolume];

	/*  SET DIRTY BIT  */
	[controller setDirtyBit];
    }

    /*  BEEP AND HIGHLIGHT FIELD IF RANGE ERROR  */
    if (rangeError) {
	NSBeep();
	[sender selectText:self];
    } 
}



- (void)aspirationSliderMoved:sender
{
    /*  GET CURRENT VALUE FROM SLIDER  */
    int currentValue = [sender intValue];

    /*  ADJUST SOUND IF VALUE IS DIFFERENT FROM OLD VALUE  */
    if (currentValue != aspirationVolume) {
	/*  SET ASPIRATION VOLUME  */
	aspirationVolume = currentValue;
	
	/*  SET FIELD TO VALUE  */
	[aspirationField setIntValue:aspirationVolume];
	
	/*  SEND PARAMETER TO THE SYNTHESIZER  */
	[synthesizer setAspirationVolume:aspirationVolume];

	/*  SET DIRTY BIT  */
	[controller setDirtyBit];
    } 
}



- (void)pulseModulationSwitchPushed:sender
{
    /*  GET STATE OF BUTTON  */
    int currentValue = [sender state];

    /*  IF STATE CHANGED, RECORD NEW STATE, AND SEND TO SYNTHESIZER  */
    if (currentValue != pulseModulation) {
	pulseModulation = currentValue;
	
	/*  ENABLE OR DISABLE CROSSMIX OFFSET FIELD  */
	#if !FIXED_CROSSMIX
	[crossmixOffsetField setEnabled:pulseModulation];
	if (pulseModulation)
	    [crossmixOffsetDB setTextColor:[NSColor blackColor]];
	else
	    [crossmixOffsetDB setTextColor:[NSColor darkGrayColor]];
	#endif

	/*  REDRAW THE CROSSMIX  */
	if (pulseModulation)
	    [crossmixView drawCrossmix:crossmixOffset];
	else
	    [crossmixView drawNoCrossmix];

	/*  RECALCULATE THE PURE AND PULSE RATIOS  */
	[self setGlottalVolume:glottalSource];
	
	/*  DISPLAY CHANGES TO SUBVIEWS OF WINDOW  */
	[noiseSourceWindow displayIfNeeded];
	
	/*  SEND VALUE TO SYNTHESIZER  */
	[synthesizer setPulseModulation:pulseModulation];

	/*  SET DIRTY BIT  */
	[controller setDirtyBit];
    } 
}




- (void)crossmixOffsetEntered:sender
{
    BOOL rangeError = NO;

    /*  GET ROUNDED VALUE  */
    int currentValue = (int)rint([sender doubleValue]);

    /*  MAKE SURE VALUE IS IN RANGE  */
    if (currentValue < CROSSMIX_MIN) {
	rangeError = YES;
	currentValue = CROSSMIX_MIN;
    }
    else if (currentValue > CROSSMIX_MAX) {
	rangeError = YES;
	currentValue = CROSSMIX_MAX;
    }

    /*  SET THE FIELD TO THE ROUNDED, CORRECTED VALUE  */
    [sender setIntValue:currentValue];

    /*  IF CURRENT VALUE DIFFERS FROM PREVIOUS VALUE, DISPLAY AND
	SEND TO SYNTHESIZER  */
    if ((int)currentValue != crossmixOffset) {
	/*  RECORD NEW VALUE  */
	crossmixOffset = (int)currentValue;

	/*  REDRAW THE CROSSMIX  */
	if (pulseModulation)
	    [crossmixView drawCrossmix:crossmixOffset];
	else
	    [crossmixView drawNoCrossmix];

	/*  REDISPLAY GLOTTAL VOLUME, PURE & PULSED RATIOS  */
	[self setGlottalVolume:glottalSource];
	
	/*  DISPLAY CHANGES TO SUBVIEWS OF WINDOW  */
	[noiseSourceWindow displayIfNeeded];
	
	/*  SEND PARAMETER TO THE SYNTHESIZER  */
	[synthesizer setCrossmixOffset:crossmixOffset];

	/*  SET DIRTY BIT  */
	[controller setDirtyBit];
    }

    /*  BEEP AND HIGHLIGHT FIELD IF RANGE ERROR  */
    if (rangeError) {
	NSBeep();
	[sender selectText:self];
    } 
}



- (void)setGlottalVolume:sender
{
    int volume = [sender glottalVolume];

    /*  DISPLAY GLOTTAL VOLUME ON CROSSMIX VIEW  */
    [crossmixView drawVolume:volume];

    /*  CALCULATE & DISPLAY PULSED AND PURE NOISE RATIOS  */
    if (pulseModulation) {
	float gain = pulsedGain((float)volume, (float)crossmixOffset);
	[pureField setFloatValue:(1.0 - gain)];
	[pulsedField setFloatValue:gain];
    }
    else {
	[pureField setFloatValue:1.0];
	[pulsedField setFloatValue:0.0];
    } 
}



- (void)adjustToNewSampleRate
{
    int nyquistFrequency;
    double newSampleRate = [resonantSystem sampleRate];

    /* CALCULATE NYQUIST FREQUENCY  */
    nyquistFrequency = (int)rint(newSampleRate / 2.0);

    /*  SET THE MAXIMUM FOR THE SLIDERS  */
    [centerFrequencySlider setMaxValue:nyquistFrequency];
    [bandwidthSlider setMaxValue:nyquistFrequency];

    /*  CHANGE CENTER FREQUENCY, IF NECESSARY  */
    if (centerFrequency > nyquistFrequency) {
	centerFrequency = nyquistFrequency;
	/*  RE-INITIALIZE FRICATION CENTER FREQUENCY OBJECTS  */
	[centerFrequencySlider setIntValue:centerFrequency];
	[centerFrequencyField setIntValue:centerFrequency];
	[synthesizer setFricationCenterFrequency:centerFrequency];
    }

    /*  CHANGE BANDWIDTH FREQUENCY, IF NECESSARY  */
    if (bandwidth > nyquistFrequency) {
	bandwidth = nyquistFrequency;
	/*  RE-INITIALIZE FRICATION BANDWIDTH OBJECTS  */
	[bandwidthSlider setIntValue:bandwidth];
	[bandwidthField setIntValue:bandwidth];
	[synthesizer setFricationBandwidth:bandwidth];
    }

    /*  DISPLAY NEW FREQUENCY RESPONSE  */
    [bandpassView drawCenterFrequency:centerFrequency bandwidth:bandwidth sampleRate:newSampleRate scale:responseScale]; 
}



- (void)windowWillMiniaturize:sender
{
    [sender setMiniwindowImage:[NSImage imageNamed:@"Synthesizer.tiff"]];
}

@end
