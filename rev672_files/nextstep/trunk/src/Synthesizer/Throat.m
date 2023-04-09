/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/Throat.m,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

# Revision 1.2  1994/09/13  21:42:38  len
# Folded in optimizations made in synthesizer.asm.
#
# Revision 1.1.1.1  1994/05/20  00:21:51  len
# Initial archive of TRM interactive Synthesizer.
#

******************************************************************************/

/*  HEADER FILES  ************************************************************/
#import "Throat.h"
#import "LowpassView.h"
#import "ResonantSystem.h"
#import "Synthesizer.h"
#import "Controller.h"
#import "dsp_control.h"
#include <math.h>



/*  LOCAL DEFINES  ***********************************************************/
#define VOLUME_MIN       0
#define VOLUME_MAX       48
#define VOLUME_DEF       12

#define CUTOFF_MIN       50
#define CUTOFF_DEF       1500

#define RESPONSE_LIN     0
#define RESPONSE_LOG     1
#define RESPONSE_DEF     RESPONSE_LIN



@implementation Throat


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
    throatVolume = VOLUME_DEF;
    throatCutoff = CUTOFF_DEF;
    responseScale = RESPONSE_DEF; 
}



- (void)awakeFromNib
{
    /*  USE OPTIMIZED DRAWING IN THE WINDOW  */
    [throatWindow useOptimizedDrawing:YES];
    
    /*  SAVE THE FRAME FOR THE WINDOW  */
    [throatWindow setFrameAutosaveName:@"throatWindow"];

    /*  SET SLIDER MIN AND MAX VALUES  */
    [volumeSlider setMinValue:VOLUME_MIN];
    [volumeSlider setMaxValue:VOLUME_MAX];
    [cutoffSlider setMinValue:CUTOFF_MIN];
    [cutoffSlider setMaxValue:[resonantSystem sampleRate]/2.0];
}



- (void)displayAndSynthesizeIvars
{
    /*  INITIALIZE VOLUME OBJECTS  */
    [volumeSlider setIntValue:throatVolume];
    [volumeField setIntValue:throatVolume];
    [synthesizer setThroatVolume:throatVolume];

    /*  INITIALIZE CUTOFF FREQUENCY OBJECTS  */
    [cutoffSlider setIntValue:throatCutoff];
    [cutoffField setIntValue:throatCutoff];
    [synthesizer setThroatCutoff:throatCutoff];

    /*  INITIALIZE FREQUENCY RESPONSE SCALE SWITCH  */
    [scaleSwitch selectCellWithTag:responseScale];

    /*  DISPLAY FREQUENCY RESPONSE  */
    [lowpassView drawCutoffFrequency:throatCutoff sampleRate:[resonantSystem sampleRate] scale:responseScale];
    
    /*  DISPLAY CHANGES TO SUBVIEWS OF WINDOW  */
    [throatWindow displayIfNeeded]; 
}



- (void)saveToStream:(NSArchiver *)typedStream
{
    /*  WRITE INSTANCE VARIABLES TO TYPED STREAM  */
    [typedStream encodeValuesOfObjCTypes:"iii", &throatVolume, &throatCutoff,
		 &responseScale]; 
}



- (void)openFromStream:(NSArchiver *)typedStream
{
    /*  READ INSTANCE VARIABLES FROM TYPED STREAM  */
    [typedStream decodeValuesOfObjCTypes:"iii", &throatVolume, &throatCutoff,
		 &responseScale];

    /*  DISPLAY THE NEW VALUES  */
    [self displayAndSynthesizeIvars]; 
}

#ifdef NeXT
- (void)_openFromStream:(NXTypedStream *)typedStream
{
    /*  READ INSTANCE VARIABLES FROM TYPED STREAM  */
    NXReadTypes(typedStream, "iii", &throatVolume, &throatCutoff,
		 &responseScale);

    /*  DISPLAY THE NEW VALUES  */
    [self displayAndSynthesizeIvars]; 
}
#endif


- (void)cutoffEntered:sender
{
    BOOL rangeError = NO;

    /*  GET CURRENT ROUNED VALUE FROM FIELD  */
    int currentValue = (int)rint([sender doubleValue]);

    /*  CORRECT OUT OF RANGE VALUES  */
    if (currentValue < CUTOFF_MIN) {
	rangeError = YES;
	currentValue = CUTOFF_MIN;
    }
    else if (currentValue > ([resonantSystem sampleRate] / 2.0)) {
	rangeError = YES;
	currentValue = [resonantSystem sampleRate] / 2.0;
    }

    /*  SET THE FIELD TO THE ROUNDED, CORRECTED VALUE  */
    [sender setIntValue:currentValue];

    /*  IF CURRENT VALUE IS DIFFERENT FROM PREVIOUS VALUE, DEAL WITH IT  */
    if (currentValue != throatCutoff) {
	/*  SET INSTANCE VARIABLE  */
	throatCutoff = currentValue;

	/*  SET SLIDER TO NEW VALUE  */
	[cutoffSlider setIntValue:throatCutoff];

	/*  DISPLAY FREQUENCY RESPONSE  */
	[lowpassView drawCutoffFrequency:throatCutoff sampleRate:[resonantSystem sampleRate] scale:responseScale];

	/*  SEND throatCutoff TO SYNTHESIZER  */
	[synthesizer setThroatCutoff:throatCutoff];

	/*  SET DIRTY BIT  */
	[controller setDirtyBit];
    }

    /*  BEEP AND HIGHLIGHT FIELD IF RANGE ERROR  */
    if (rangeError) {
	NSBeep();
	[sender selectText:self];
    } 
}



- (void)cutoffSliderMoved:sender
{
    /*  GET CURRENT VALUE FROM SLIDER  */
    int currentValue = [sender intValue];

    /*  ADJUST SOUND IF VALUE IS DIFFERENT FROM OLD VALUE  */
    if (currentValue != throatCutoff) {
	/*  SET THROAT CUTOFF FREQUENCY  */
	throatCutoff = currentValue;
	
	/*  SET FIELD TO VALUE  */
	[cutoffField setIntValue:throatCutoff];
	
	/*  DISPLAY FREQUENCY RESPONSE  */
	[lowpassView drawCutoffFrequency:throatCutoff sampleRate:[resonantSystem sampleRate] scale:responseScale];

	/*  SEND PARAMETER TO THE SYNTHESIZER  */
	[synthesizer setThroatCutoff:throatCutoff];

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

	/*  DISPLAY FREQUENCY RESPONSE  */
	[lowpassView drawCutoffFrequency:throatCutoff sampleRate:[resonantSystem sampleRate] scale:responseScale];

	/*  SET DIRTY BIT  */
	[controller setDirtyBit];
    } 
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
    if (currentValue != throatVolume) {
	/*  SET INSTANCE VARIABLE  */
	throatVolume = currentValue;

	/*  SET SLIDER TO NEW VALUE  */
	[volumeSlider setIntValue:throatVolume];

	/*  SEND THROATVOLUME TO SYNTHESIZER  */
	[synthesizer setThroatVolume:throatVolume];

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

    /*  ADJUST SOUND IF VALUE IS DIFFERENT FROM OLD VALUE  */
    if (currentValue != throatVolume) {
	/*  SET THROAT VOLUME  */
	throatVolume = currentValue;
	
	/*  SET FIELD TO VALUE  */
	[volumeField setIntValue:throatVolume];
	
	/*  SEND PARAMETER TO THE SYNTHESIZER  */
	[synthesizer setThroatVolume:throatVolume];

	/*  SET DIRTY BIT  */
	[controller setDirtyBit];
    } 
}



- (void)adjustToNewSampleRate
{
    int nyquistFrequency;
    double newSampleRate = [resonantSystem sampleRate];

    /* CALCULATE NYQUIST FREQUENCY  */
    nyquistFrequency = (int)rint(newSampleRate / 2.0);

    /*  SET THE MAXIMUM FOR THE CUTOFF SLIDER  */
    [cutoffSlider setMaxValue:nyquistFrequency];

    /*  CHANGE CUTOFF FREQUENCY, IF NECESSARY  */
    if (throatCutoff > nyquistFrequency) {
	throatCutoff = nyquistFrequency;
	
	/*  RE-INITIALIZE CUTOFF FREQUENCY OBJECTS  */
	[cutoffSlider setIntValue:throatCutoff];
	[cutoffField setIntValue:throatCutoff];
	[synthesizer setThroatCutoff:throatCutoff];
    }

    /*  DISPLAY FREQUENCY RESPONSE  */
    [lowpassView drawCutoffFrequency:throatCutoff sampleRate:[resonantSystem sampleRate] scale:responseScale]; 
}



- (void)windowWillMiniaturize:sender
{
    [sender setMiniwindowImage:[NSImage imageNamed:@"Synthesizer.tiff"]];
}

@end
