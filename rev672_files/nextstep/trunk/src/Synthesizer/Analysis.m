/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/Analysis.m,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

# Revision 1.1.1.1  1994/05/20  00:21:59  len
# Initial archive of TRM interactive Synthesizer.
#

******************************************************************************/

#import "Analysis.h"
#import "Synthesizer.h"
#import "SoundData.h"
#import "AnalysisData.h"
#import "AnalysisWindow.h"
#import "SpectrographView.h"
#import "SpectrumView.h"
#import "dsp_control.h"
#include <math.h>


/*  LOCAL DEFINES  ***********************************************************/
#define BIN_SIZE_DEF          256

#define WINDOW_TYPE_DEF       BLACKMAN

#define ALPHA_MIN             0.0
#define ALPHA_MAX             1.0
#define ALPHA_DEF             0.54

#define BETA_MIN              0.0
#define BETA_MAX              10.0
#define BETA_DEF              5.0

#define CONTINUOUS            0
#define QUANTIZED             1
#define GRAY_LEVEL_DEF        CONTINUOUS

#define LINEAR                0
#define LOG                   1
#define MAGNITUDE_SCALE_DEF   LOG

#define THRESHOLD_LINEAR_MIN  0.0
#define THRESHOLD_LINEAR_MAX  1.0
#define UPPER_THRESH_LIN_DEF  0.15
#define LOWER_THRESH_LIN_DEF  THRESHOLD_LINEAR_MIN

#define THRESHOLD_LOG_MIN     (-120)
#define THRESHOLD_LOG_MAX     0
#define UPPER_THRESH_LOG_DEF  (-18)
#define LOWER_THRESH_LOG_DEF  (-66)

#define LOWER                 0
#define UPPER                 1

#define SNAPSHOT_MODE         0
#define CONTINUOUS_MODE       1
#define UPDATE_MODE_DEF       SNAPSHOT_MODE

#define UPDATE_RATE_MIN       0.1
#define UPDATE_RATE_MAX       5.0
#define UPDATE_RATE_DEF       1.0

#define NORMALIZE_INPUT_DEF   YES
#define SPECTROGRAPH_GRID_DEF NO
#define SPECTRUM_GRID_DEF     YES



@implementation Analysis

- init
{
    /*  DO REGULAR INITIALIZATION  */
    [super init];

    /*  SET DEFAULT INSTANCE VARIABLES  */
    [self defaultInstanceVariables];

    /*  SOME IVARS ARE SET ONLY AT INIT TIME  */
    updateMode = UPDATE_MODE_DEF;
    updateRate = UPDATE_RATE_DEF;

    /*  ALLOCATE A SOUND DATA OBJECT  */
    soundDataObject = [[SoundData alloc] init];

    /*  ALLOCATE AN ANALYSIS DATA OBJECT  */
    analysisDataObject = [[AnalysisData alloc] init];

    return self;
}



- (void)dealloc
{
    /*  FREE THE SOUND DATA OBJECT  */
    [soundDataObject release];

    /*  FREE THE ANALYSIS DATA OBJECT  */
    [analysisDataObject release];

    /*  DO REGULAR FREE  */
    [super dealloc]; 
}



- (void)defaultInstanceVariables
{
    /*  SET DEFAULTS  */
    normalizeInput = NORMALIZE_INPUT_DEF;
    binSize = BIN_SIZE_DEF;
    windowType = WINDOW_TYPE_DEF;
    alpha = ALPHA_DEF;
    beta = BETA_DEF;
    grayLevel = GRAY_LEVEL_DEF;
    magnitudeScale = MAGNITUDE_SCALE_DEF;
    linearUpperThreshold = UPPER_THRESH_LIN_DEF;
    linearLowerThreshold = LOWER_THRESH_LIN_DEF;
    logUpperThreshold = UPPER_THRESH_LOG_DEF;
    logLowerThreshold = LOWER_THRESH_LOG_DEF;
    spectrographGrid = SPECTROGRAPH_GRID_DEF;
    spectrumGrid = SPECTRUM_GRID_DEF; 
}



- (void)awakeFromNib
{
    /*  USE OPTIMIZED DRAWING IN THE WINDOW  */
    [analysisWindow useOptimizedDrawing:YES];

    /*  SAVE THE FRAME FOR THE WINDOW  */
    [analysisWindow setFrameAutosaveName:@"analysisWindow"];

    /*  SET FORMAT OF FIELDS  */
    [binSizeFrequency setFloatingPointFormat:NO left:3 right:2];
    [windowForm setFloatingPointFormat:NO left:3 right:2];
    [rateForm setFloatingPointFormat:NO left:1 right:1];

    /*  SET UPDATE RATE  */
    [rateForm setFloatValue:updateRate];
}



- (void)displayAndSynthesizeIvars
{
    /*  SET INPUT AMPLITUDE NORMALIZE SWITCH  */
    [normalizeSwitch setState:normalizeInput];

    /*  SET BIN SIZE  */
    [binSizePopUp selectItemAtIndex:[binSizePopUp indexOfItemWithTag: binSize]];
    [binSizePopUp setTitle: [binSizePopUp titleOfSelectedItem]];
    [self binSizeSelected: binSizePopUp ];

    /*  SET WINDOW TYPE  */
    [windowPopUp selectItemAtIndex:[windowPopUp indexOfItemWithTag: binSize]];
    [windowPopUp setTitle: [windowPopUp titleOfSelectedItem]];
    [self windowSelected: windowPopUp];

    /*  SET GRAY LEVEL  */
    [grayLevelPopUp selectItemAtIndex:
	[grayLevelPopUp indexOfItemWithTag: binSize]];
    [grayLevelPopUp setTitle: [grayLevelPopUp titleOfSelectedItem]];
    [self grayLevelSelected: grayLevelPopUp];

    /*  SET MAGNITUDE AND THRESHOLD LEVELS  */
    [magnitudePopUp selectItemAtIndex:
	[magnitudePopUp indexOfItemWithTag: binSize]];
    [magnitudePopUp setTitle: [magnitudePopUp titleOfSelectedItem]];
    [self magnitudeScaleSelected: magnitudePopUp];

    /*  SET SPECTROGRAPH AND SPECTRUM GRID SWITCHES  */
    [spectrographGridButton setState:spectrographGrid];
    [spectrograph setGrid:spectrographGrid];
    [spectrumGridButton setState:spectrumGrid];
    [spectrum setGrid:spectrumGrid];


    /*  DISPLAY CHANGES TO SUBVIEWS OF WINDOW  */
    [analysisWindow displayIfNeeded]; 
}

- (void)saveToStream:(NSArchiver *)typedStream
{
    /*  WRITE INSTANCE VARIABLES TO TYPED STREAM  */
    [typedStream encodeValuesOfObjCTypes:"ciiffiiffiicc", &normalizeInput, &binSize,
		 &windowType, &alpha, &beta, &grayLevel, &magnitudeScale,
		 &linearUpperThreshold, &linearLowerThreshold,
		 &logUpperThreshold, &logLowerThreshold,
		 &spectrographGrid, &spectrumGrid]; 
}



- (void)openFromStream:(NSArchiver *)typedStream
{
    /*  READ INSTANCE VARIABLES FROM TYPED STREAM  */
    [typedStream decodeValuesOfObjCTypes:"ciiffiiffiicc", &normalizeInput, &binSize,
		&windowType, &alpha, &beta, &grayLevel, &magnitudeScale,
		&linearUpperThreshold, &linearLowerThreshold,
		&logUpperThreshold, &logLowerThreshold,
		&spectrographGrid, &spectrumGrid];

    /*  DISPLAY THE NEW VALUES  */
    [self displayAndSynthesizeIvars]; 
}

#ifdef NeXT
/* Typed Stream Compatibility */
- (void)_openFromStream:(NXTypedStream *)typedStream
{
    /*  READ INSTANCE VARIABLES FROM TYPED STREAM  */
    NXReadTypes(typedStream, "ciiffiiffiicc", &normalizeInput, &binSize,
		&windowType, &alpha, &beta, &grayLevel, &magnitudeScale,
		&linearUpperThreshold, &linearLowerThreshold,
		&logUpperThreshold, &logLowerThreshold,
		&spectrographGrid, &spectrumGrid);

    /*  DISPLAY THE NEW VALUES  */
    [self displayAndSynthesizeIvars]; 
}
#endif


- (void)windowWillMiniaturize:sender
{
    [sender setMiniwindowImage:[NSImage imageNamed:@"Synthesizer.tiff"]];
}



- (void)setAnalysisEnabled:(BOOL)flag
{
    /*  RECORD IF ANALYSIS IS ENABLED  */
    analysisEnabled = flag;

    /*  ENABLE/DISABLE BUTTONS ACCORDING TO MODE  */
    if (analysisEnabled) {
	/*  ENABLE UPDATEMATRIX  */
	[updateMatrix setEnabled:YES];
	/*  ENABLE/DISABLE BUTTONS ACCORDING TO MODE  */
	[self updateMatrixPushed:updateMatrix];
    }
    else {
	/*  DISABLE ALL UPDATE CONTROLS  */
	[updateMatrix setEnabled:NO];
	[doAnalysisButton setEnabled:NO];
	[rateForm setEnabled:NO];
	[rateSecond setTextColor:[NSColor darkGrayColor]];
    }

    /*  DISPLAY CHANGES TO SUBVIEWS OF WINDOW  */
    [analysisWindow displayIfNeeded]; 
}

- startContinuousAnalysis
{
    /*  CREATE A TIMED ENTRY, AS LONG AS ONE DOESN'T ALREADY EXIST  */
    if (!timedEntry)
	timedEntry = [[NSTimer scheduledTimerWithTimeInterval:updateRate 
			target: self
			selector: @selector(doAnalysisButtonPushed:)
			userInfo: nil
			repeats:YES] 
			retain];

    return self;
}



- stopContinuousAnalysis
{
    /*  REMOVE THE TIMED ENTRY, IF IT EXISTS  */
    if (timedEntry)
      {
	[timedEntry invalidate]; [timedEntry release];
      }

    /*  SET THE TIMED ENTRY TAG TO NULL  */
    timedEntry = NULL;

    return self;
}



- resetContinuousAnalysis
{
    /*  STOP THE ANALYSIS  */
    [self stopContinuousAnalysis];

    /*  RESTART THE ANALYSIS WITH THE NEW RATE  */
    [self startContinuousAnalysis];

    return self;
}



- (void)setRunning:(BOOL)flag
{
    /*  RECORD WHETHER RUNNING OR NOT  */
    running = flag;

    /*  ENABLE/DISABLE DO ANALYSIS BUTTON, ACCORDING TO STATE  */
    if (analysisEnabled && running && (updateMode == SNAPSHOT_MODE))
	[doAnalysisButton setEnabled:YES];
    else
	[doAnalysisButton setEnabled:NO];

    /*  START OR STOP CONTINUOUS ANALYSIS, IF IN CONTINUOUS MODE  */
    if ((updateMode == CONTINUOUS_MODE) && analysisEnabled) {
	if (running)
	    [self startContinuousAnalysis];
	else
	    [self stopContinuousAnalysis];
    } 
}



- (void)normalizeSwitchPushed:sender
{
    /*  RECORD VALUE  */
    normalizeInput = [sender state];

    /*  ANALYZE SOUND DATA, PUT INTO ANALYSIS DATA OBJECT  */
    [analysisDataObject analyzeSoundData:soundDataObject windowSize:binSize windowType:windowType alpha:alpha beta:beta normalizeAmplitude:normalizeInput];

    /*  DISPLAY  */
    [self displayAnalysis]; 
}



- (void)magnitudeFormEntered:sender
{
    BOOL rangeError = NO;
    id selectedCell = [sender selectedCell];
    int threshold = [selectedCell tag];

    
    if (magnitudeScale == LINEAR) {
	/*  GET CURRENT VALUE FROM FIELD  */
	float currentValue = [selectedCell floatValue];

	/*  CHECK FOR RANGE ERRORS  */
	if (threshold == UPPER) {
	    if (currentValue < linearLowerThreshold) {
		currentValue = linearLowerThreshold;
		rangeError = YES;
	    }
	    else if (currentValue > THRESHOLD_LINEAR_MAX) {
		currentValue = THRESHOLD_LINEAR_MAX;
		rangeError = YES;
	    }
	    /*  SAVE THE VALUE  */
	    linearUpperThreshold = currentValue;
	}
	else {
	    if (currentValue < THRESHOLD_LINEAR_MIN) {
		currentValue = THRESHOLD_LINEAR_MIN;
		rangeError = YES;
	    }
	    else if (currentValue > linearUpperThreshold) {
		currentValue = linearUpperThreshold;
		rangeError = YES;
	    }
	    /*  SAVE THE VALUE  */
	    linearLowerThreshold = currentValue;
	}
    }
    else {
	/*  GET CURRENT (ROUNDED) VALUE FROM FIELD  */
	int currentValue = (int)rint([sender doubleValue]);

	/*  CHECK FOR RANGE ERRORS  */
	if (threshold == UPPER) {
	    if (currentValue < logLowerThreshold) {
		currentValue = logLowerThreshold;
		rangeError = YES;
	    }
	    else if (currentValue > THRESHOLD_LOG_MAX) {
		currentValue = THRESHOLD_LOG_MAX;
		rangeError = YES;
	    }
	    /*  SAVE THE VALUE  */
	    logUpperThreshold = currentValue;

	    /*  DISPLAY ROUNDED VALUE  */
	    [selectedCell setIntValue:logUpperThreshold];
	}
	else {
	    if (currentValue < THRESHOLD_LOG_MIN) {
		currentValue = THRESHOLD_LOG_MIN;
		rangeError = YES;
	    }
	    else if (currentValue > logUpperThreshold) {
		currentValue = logUpperThreshold;
		rangeError = YES;
	    }
	    /*  SAVE THE VALUE  */
	    logLowerThreshold = currentValue;

	    /*  DISPLAY ROUNDED VALUE  */
	    [selectedCell setIntValue:logLowerThreshold];
	}
    }

    /*  DISPLAY  */
    [self displayAnalysis];

    /*  BEEP AND HIGHLIGHT FIELD IF RANGE ERROR  */
    if (rangeError) {
	NSBeep();
	if (magnitudeScale == LINEAR) {
	    if (threshold == UPPER)
		[selectedCell setFloatValue:linearUpperThreshold];
	    else
		[selectedCell setFloatValue:linearLowerThreshold];
	}
	else {
	    if (threshold == UPPER)
		[selectedCell setIntValue:logUpperThreshold];
	    else
		[selectedCell setIntValue:logLowerThreshold];
	}
	[sender selectCellWithTag:threshold];
    } 
}



- (void)magnitudeScaleSelected:sender
{
    /*  RECORD MAGNITUDE SCALE TYPE  */
    magnitudeScale = [[sender selectedCell] tag];


    /*  DEAL WITH THRESHOLD DISPLAY  */
    switch (magnitudeScale) {
      case LINEAR:
	[[magnitudeForm cellWithTag:UPPER] setFloatingPointFormat:NO left:1 right:3];
	[[magnitudeForm cellWithTag:LOWER] setFloatingPointFormat:NO left:1 right:3];
	[[magnitudeForm cellWithTag:UPPER] setFloatValue:linearUpperThreshold];
	[[magnitudeForm cellWithTag:LOWER] setFloatValue:linearLowerThreshold];
	[magnitudeLabel setTextColor:[NSColor lightGrayColor]];
	break;
      case LOG:
	[[magnitudeForm cellWithTag:UPPER] setFloatingPointFormat:NO left:2 right:0];
	[[magnitudeForm cellWithTag:LOWER] setFloatingPointFormat:NO left:2 right:0];
	[[magnitudeForm cellWithTag:UPPER] setIntValue:logUpperThreshold];
	[[magnitudeForm cellWithTag:LOWER] setIntValue:logLowerThreshold];
	[magnitudeLabel setTextColor:[NSColor blackColor]];
	break;
      default:
	break;
    }

    /*  DISPLAY  */
    [self displayAnalysis];
    [analysisWindow displayIfNeeded]; 
}



- (void)binSizeSelected:sender
{
    /*  RECORD THE BIN SIZE  */
    binSize = [[sender selectedItem] tag];

    /*  CALCULATE AND DISPLAY THE BIN SIZE IN HZ  */
    [binSizeFrequency setFloatValue:(OUTPUT_SRATE/2.0)/((float)binSize/2.0)];

    /*  ANALYZE SOUND DATA, PUT INTO ANALYSIS DATA OBJECT  */
    [analysisDataObject analyzeSoundData:soundDataObject windowSize:binSize windowType:windowType alpha:alpha beta:beta normalizeAmplitude:normalizeInput];

    /*  DISPLAY  */
    [self displayAnalysis]; 
}



- (void)doAnalysisButtonPushed:sender
{
    /*  GET SOUND DATA FROM THE SYNTHESIZER  */
    [synthesizer fillSoundData:soundDataObject];

    /*  ANALYZE SOUND DATA, PUT INTO ANALYSIS DATA OBJECT  */
    [analysisDataObject analyzeSoundData:soundDataObject windowSize:binSize windowType:windowType alpha:alpha beta:beta normalizeAmplitude:normalizeInput];

    /*  DISPLAY  */
    [self displayAnalysis]; 
}



- (void)grayLevelSelected:sender
{
    /*  RECORD GRAYLEVEL TYPE  */
    grayLevel = [[sender selectedItem] tag];

    /*  DISPLAY  */
    [self displayAnalysis]; 
}



- (void)rateFormEntered:sender
{
    BOOL rangeError = NO;

    /*  GET CURRENT VALUE FROM FIELD  */
    float currentValue = [sender floatValue];
    
    /*  RETURN IMMEDIATELY IF THE RATE HAS NOT CHANGED  */
    if (currentValue == updateRate)
	return;

    /*  CHECK FOR RANGE ERRORS  */
    if (currentValue < UPDATE_RATE_MIN) {
	currentValue = UPDATE_RATE_MIN;
	rangeError = YES;
    }
    else if (currentValue > UPDATE_RATE_MAX) {
	currentValue = UPDATE_RATE_MAX;
	rangeError = YES;
    }

    /*  SAVE THE VALUE  */
    updateRate = currentValue;

    /*  RESET THE CONTINUOUS ANALYSIS RATE, IF CURRENTLY RUNNING  */
    if ((updateMode == CONTINUOUS_MODE) && running && analysisEnabled)
	[self resetContinuousAnalysis];

    /*  BEEP AND HIGHLIGHT FIELD IF RANGE ERROR  */
    if (rangeError) {
	NSBeep();
	[sender setFloatValue:updateRate];
	[sender selectText:self];
    } 
}



- (void)spectrographGridPushed:sender
{
    /*  RECORD GRID STATUS  */
    spectrographGrid = [sender state];

    /*  SET THE GRID ON THE SPECTROGRAPH  */
    [spectrograph setGrid:spectrographGrid]; 
}



- (void)spectrumGridPushed:sender
{
    /*  RECORD GRID STATUS  */
    spectrumGrid = [sender state];

    /*  SET THE GRID ON THE SPECTRUM  */
    [spectrum setGrid:spectrumGrid]; 
}



- (void)updateMatrixPushed:sender
{
    /*  GET THE UPDATE STATE  */
    int currentValue = [[sender selectedCell] tag];

    /*  ENABLE/DISABLE OTHER BUTTONS ACCORDING TO MODE  */
    if (currentValue == SNAPSHOT_MODE) {
	if (running)
	    [doAnalysisButton setEnabled:YES];
	else
	    [doAnalysisButton setEnabled:NO];
	[rateForm setEnabled:NO];
	[rateSecond setTextColor:[NSColor darkGrayColor]];
    }
    else {
	[doAnalysisButton setEnabled:NO];
	[rateForm setEnabled:YES];
	[rateSecond setTextColor:[NSColor blackColor]];
    }

    /*  DISPLAY CHANGES TO SUBVIEWS OF WINDOW  */
    [analysisWindow displayIfNeeded];

    /*  RETURN IMMEDIATELY, IF NO CHANGE OF MODE  */
    if (currentValue == updateMode)
	return;

    /*  RECORD CHANGED UPDATE MODE  */
    updateMode = currentValue;

    /*  START OR STOP CONTINUOUS ANALYSIS, IF CURRENTLY RUNNING  */
    if (running && analysisEnabled) {
	if (updateMode == CONTINUOUS_MODE)
	    [self startContinuousAnalysis];
	else
	    [self stopContinuousAnalysis];
    } 
}



- (void)windowFormEntered:sender
{
    BOOL rangeError = NO;

    /*  GET CURRENT VALUE FROM FIELD  */
    float currentValue = [sender floatValue];

    if (windowType == HAMMING) {
	/*  CHECK FOR RANGE ERRORS  */
	if (currentValue < ALPHA_MIN) {
	    currentValue = ALPHA_MIN;
	    rangeError = YES;
	}
	else if (currentValue > ALPHA_MAX) {
	    currentValue = ALPHA_MAX;
	    rangeError = YES;
	}
	/*  SAVE THE VALUE  */
	alpha = currentValue;
    }
    else {
	/*  CHECK FOR RANGE ERRORS  */
	if (currentValue < BETA_MIN) {
	    currentValue = BETA_MIN;
	    rangeError = YES;
	}
	else if (currentValue > BETA_MAX) {
	    currentValue = BETA_MAX;
	    rangeError = YES;
	}
	/*  SAVE THE VALUE  */
	beta = currentValue;
    }

    /*  ANALYZE SOUND DATA, PUT INTO ANALYSIS DATA OBJECT  */
    [analysisDataObject analyzeSoundData:soundDataObject windowSize:binSize windowType:windowType alpha:alpha beta:beta normalizeAmplitude:normalizeInput];

    /*  DISPLAY  */
    [self displayAnalysis];

    /*  BEEP AND HIGHLIGHT FIELD IF RANGE ERROR  */
    if (rangeError) {
	NSBeep();
	[sender setFloatValue:currentValue];
	[sender selectText:self];
    } 
}



- (void)windowSelected:sender
{
    /*  RECORD WINDOW TYPE  */
    windowType = [[sender selectedItem] tag];

    /*  DEAL WITH ALPHA OR BETA DISPLAY, IF NECESSARY  */
    switch (windowType) {
      case HAMMING:
	[windowForm setEnabled:YES];
	[[windowForm cellAtIndex:0] setTitle:@"Alpha:"];
	[[windowForm cellAtIndex:0] setFloatValue:alpha];
	break;
      case KAISER:
	[windowForm setEnabled:YES];
	[[windowForm cellAtIndex:0] setTitle:@"Beta:"];
	[[windowForm cellAtIndex:0] setFloatValue:beta];
	break;
      case RECTANGULAR:
      case TRIANGULAR:
      case HANNING:
      case BLACKMAN:
      default:
	[windowForm setEnabled:NO];
	[[windowForm cellAtIndex:0] setTitle:@"           "];
	[[windowForm cellAtIndex:0] setStringValue:@""];
	break;
    }
    
    /*  ANALYZE SOUND DATA, PUT INTO ANALYSIS DATA OBJECT  */
    [analysisDataObject analyzeSoundData:soundDataObject windowSize:binSize windowType:windowType alpha:alpha beta:beta normalizeAmplitude:normalizeInput];

    /*  DISPLAY  */
    [self displayAnalysis]; 
}



- (void)displayAnalysis
{
    /*  SEND ANALYSIS TO DISPLAYS  */
    [spectrograph displayAnalysis:analysisDataObject
		  grayLevel:grayLevel
		  magnitudeScale:magnitudeScale
		  linearUpperThreshold:linearUpperThreshold
		  linearLowerThreshold:linearLowerThreshold
		  logUpperThreshold:(float)logUpperThreshold
		  logLowerThreshold:(float)logLowerThreshold];

    [spectrum displayAnalysis:analysisDataObject magnitudeScale:magnitudeScale]; 
}

@end
