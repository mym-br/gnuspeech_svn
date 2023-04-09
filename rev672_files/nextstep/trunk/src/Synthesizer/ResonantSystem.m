/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/ResonantSystem.m,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

# Revision 1.4  1994/10/04  18:37:32  len
# Changed nose and mouth aperture filter coefficients, so now specified
# as Hz values (which scale appropriately as the tube length changes), rather
# than arbitrary coefficient values (which don't scale).
#
# Revision 1.3  1994/09/19  03:05:27  len
# Resectioned the TRM to 10 sections in 8 regions.  Also
# changed friction injection to be continous from sections
# 3 to 10.
#
# Revision 1.2  1994/09/13  21:42:31  len
# Folded in optimizations made in synthesizer.asm.
#
# Revision 1.1.1.1  1994/05/20  00:21:45  len
# Initial archive of TRM interactive Synthesizer.
#

******************************************************************************/

/*  HEADER FILES  ************************************************************/
#import "ResonantSystem.h"
#import "ApertureView.h"
#import "NoiseSource.h"
#import "Throat.h"
#import "PositionView.h"
#import "Synthesizer.h"
#import "Controller.h"
#import "dsp_control.h"
#include <math.h>


/*  LOCAL DEFINES  ***********************************************************/
#define RADIUS                0
#define DIAMETER              1
#define AREA                  2

#define DIAMETER_MIN          0.0
#define DIAMETER_MAX          6.0
#define VELUM_DIAMETER_MAX    3.0

#define PHARYNX_SECTION1_DEF  1.6
#define PHARYNX_SECTION2_DEF  1.6
#define PHARYNX_SECTION3_DEF  1.6

#define VELUM_SECTION1_DEF    0.0

#define ORAL_SECTION1_DEF     1.6
#define ORAL_SECTION2_DEF     1.6
#define ORAL_SECTION3_DEF     1.6
#define ORAL_SECTION4_DEF     1.6
#define ORAL_SECTION5_DEF     1.6

#define NASAL_SECTION1_DEF    2.7
#define NASAL_SECTION2_DEF    3.4
#define NASAL_SECTION3_DEF    3.4
#define NASAL_SECTION4_DEF    2.6
#define NASAL_SECTION5_DEF    1.8

#define LOSS_FACTOR_MIN       0.0
#define LOSS_FACTOR_MAX       5.0
#define LOSS_FACTOR_DEF       2.0

#define APERTURE_SCALING_MIN  (DIAMETER_MAX + 0.1)
#define APERTURE_SCALING_MAX  (DIAMETER_MAX * 4.0)
#define APERTURE_SCALING_DEF  APERTURE_SCALING_MIN

#define FILTER_MIN            0.0
#define FILTER_MAX            0.99
#define FILTER_DEF            0.75

#define APERTURE_COEF_MIN     100.0
#define APERTURE_COEF_DEF     4000.0

#define RESPONSE_LIN          0
#define RESPONSE_LOG          1
#define RESPONSE_DEF          RESPONSE_LIN

#define LENGTH_MIN            10.0
#define LENGTH_MAX            20.0
#define LENGTH_DEF            17.5

#define TEMPERATURE_MIN       25.0
#define TEMPERATURE_MAX       40.0
#define TEMPERATURE_DEF       32.0

#define CONTROL_RATE          100.0


#define PI                    3.14159265358979



@implementation ResonantSystem

- init
{
    /*  DO REGULAR INITIALIZATION  */
    [super init];

    /*  SET DEFAULT INSTANCE VARIABLES  */
    [self defaultInstanceVariables];

    return self;
}



- (void)defaultInstanceVariables
{
    /*  SET DIAMETERS  */
    pharynxDiameter[0] = PHARYNX_SECTION1_DEF;
    pharynxDiameter[1] = PHARYNX_SECTION2_DEF;
    pharynxDiameter[2] = PHARYNX_SECTION3_DEF;

    velumDiameter[0] = VELUM_SECTION1_DEF;

    oralDiameter[0] = ORAL_SECTION1_DEF;
    oralDiameter[1] = ORAL_SECTION2_DEF;
    oralDiameter[2] = ORAL_SECTION3_DEF;
    oralDiameter[3] = ORAL_SECTION4_DEF;
    oralDiameter[4] = ORAL_SECTION5_DEF;

    nasalDiameter[0] = NASAL_SECTION1_DEF;
    nasalDiameter[1] = NASAL_SECTION2_DEF;
    nasalDiameter[2] = NASAL_SECTION3_DEF;
    nasalDiameter[3] = NASAL_SECTION4_DEF;
    nasalDiameter[4] = NASAL_SECTION5_DEF;

    /*  SET LOSS FACTOR  */
    lossFactor = LOSS_FACTOR_DEF / 100.0;

    /*  SET APERTURE SCALING FACTOR  */
    apertureScaling = APERTURE_SCALING_DEF;

    /*  SET MOUTH AND NOSE FILTER COEFFICIENTS  */
    mouthFilterCoefficient = noseFilterCoefficient = APERTURE_COEF_DEF;

    /*  SET DISPLAY SCALES  */
    mouthResponseScale = noseResponseScale = RESPONSE_DEF;

    /*  SET LENGTH, TEMPERATURE, & SAMPLING RATE PARAMETERS  */
    length = LENGTH_DEF;
    temperature = TEMPERATURE_DEF;
    [self calculateSampleRate]; 
}



- (void)calculateSampleRate
{
    double c, speedOfSound();


    /*  CALCULATE THE SPEED OF SOUND AT CURRENT TEMPERATURE  */
    c = speedOfSound(temperature);

    /*  CALCULATE THE CONTROL PERIOD  */
    controlPeriod = (int)rint((c * TOTAL_SECTIONS * 100.0) /
			      (length * CONTROL_RATE));

    /*  CALCULATE THE NEAREST SAMPLE RATE  */
    sampleRate = CONTROL_RATE * (double)controlPeriod;

    /*  CALCULATE THE ACTUAL LENGTH OF THE TUBE  */
    actualLength = (c * TOTAL_SECTIONS * 100.0) / sampleRate; 
}



- (void)awakeFromNib
{
    NSArray *list;
    unsigned int i;

    /*  USE OPTIMIZED DRAWING IN THE WINDOW  */
    [resonantSystemWindow useOptimizedDrawing:YES];

    /*  SAVE THE FRAME FOR THE WINDOW  */
    [resonantSystemWindow setFrameAutosaveName:@"resonantSystemWindow"];

    /*  SET FORMAT OF AREA SLIDERS  */
    [pharynxSection1 setFloatingPointFormat:NO left:4 right:2];
    [pharynxSection2 setFloatingPointFormat:NO left:4 right:2];
    [pharynxSection3 setFloatingPointFormat:NO left:4 right:2];
    [velumSection setFloatingPointFormat:NO left:4 right:2];
    [oralSection1 setFloatingPointFormat:NO left:4 right:2];
    [oralSection2 setFloatingPointFormat:NO left:4 right:2];
    [oralSection3 setFloatingPointFormat:NO left:4 right:2];
    [oralSection4 setFloatingPointFormat:NO left:4 right:2];
    [oralSection5 setFloatingPointFormat:NO left:4 right:2];
    [nasalSection1 setFloatingPointFormat:NO left:4 right:2];
    [nasalSection2 setFloatingPointFormat:NO left:4 right:2];
    [nasalSection3 setFloatingPointFormat:NO left:4 right:2];
    [nasalSection4 setFloatingPointFormat:NO left:4 right:2];
    [nasalSection5 setFloatingPointFormat:NO left:4 right:2];

    /*  SET FORMAT OF PHARYNX MATRIX CELLS  */
    list = [pharynxMatrix cells];
    for (i = 0; i < [list count]; i++)
	[[list objectAtIndex:i] setFloatingPointFormat:NO left:2 right:2];

    /*  SET FORMAT OF VELUM MATRIX CELLS  */
    list = [velumMatrix cells];
    for (i = 0; i < [list count]; i++)
	[[list objectAtIndex:i] setFloatingPointFormat:NO left:2 right:2];

    /*  SET FORMAT OF ORAL MATRICES CELLS  */
    list = [oralMatrix1 cells];
    for (i = 0; i < [list count]; i++)
	[[list objectAtIndex:i] setFloatingPointFormat:NO left:2 right:2];
    list = [oralMatrix2 cells];
    for (i = 0; i < [list count]; i++)
	[[list objectAtIndex:i] setFloatingPointFormat:NO left:2 right:2];

    /*  SET FORMAT OF NASAL MATRIX CELLS  */
    list = [nasalMatrix cells];
    for (i = 0; i < [list count]; i++)
	[[list objectAtIndex:i] setFloatingPointFormat:NO left:2 right:2];

    /*  SET FORMAT OF JUNCTION LOSS FACTOR CONTROLS  */
    [lossFactorSlider setMinValue:LOSS_FACTOR_MIN];
    [lossFactorSlider setMaxValue:LOSS_FACTOR_MAX];
    [lossFactorField setFloatingPointFormat:NO left:2 right:2];
    [dampingFactorField setFloatingPointFormat:NO left:3 right:2];

    /*  SET FORMAT OF APERTURE MATRIX CELLS  */
    list = [apertureMatrix cells];
    for (i = 0; i < [list count]; i++)
	[[list objectAtIndex:i] setFloatingPointFormat:NO left:3 right:2];

    /*  SET FORMAT OF MOUTH FILTER COEFFICIENT CONTROLS  */
    [mouthFilterSlider setMinValue:APERTURE_COEF_MIN];
    [mouthFilterSlider setMaxValue:sampleRate/2.0];
    [mouthFilterField setFloatingPointFormat:NO left:5 right:0];

    /*  SET FORMAT OF NOSE FILTER COEFFICIENT CONTROLS  */
    [noseFilterSlider setMinValue:APERTURE_COEF_MIN];
    [noseFilterSlider setMaxValue:sampleRate/2.0];
    [noseFilterField setFloatingPointFormat:NO left:5 right:0];

    /*  SET FORMAT OF LENGTH CONTROLS  */
    [lengthSlider setMinValue:LENGTH_MIN];
    [lengthSlider setMaxValue:LENGTH_MAX];
    [lengthField setFloatingPointFormat:NO left:2 right:2];

    /*  SET FORMAT OF TEMPERATURE CONTROLS  */
    [temperatureSlider setMinValue:TEMPERATURE_MIN];
    [temperatureSlider setMaxValue:TEMPERATURE_MAX];
    [temperatureField setFloatingPointFormat:NO left:2 right:2];

    /*  SET FORMAT OF MISC. FIELDS  */
    [actualLengthField setFloatingPointFormat:NO left:2 right:4];
    [sampleRateField setFloatingPointFormat:NO left:5 right:2];
}



- (void)displayAndSynthesizeIvars
{
    int i;

    /*  INITIALIZE PHARYNX DISPLAY  */
    for (i = 0; i < PHARYNX_REGIONS; i++) {
	[[pharynxMatrix cellAtRow:DIAMETER column:i] setDoubleValue:pharynxDiameter[i]];
	[pharynxMatrix selectCellAtRow:DIAMETER column:i];
	[self pharynxMatrixEntered:pharynxMatrix];
    }

    /*  INITIALIZE VELUM DISPLAY  */
    for (i = 0; i < VELUM_REGIONS; i++) {
	[[velumMatrix cellAtRow:DIAMETER column:i] setDoubleValue:velumDiameter[i]];
	[velumMatrix selectCellAtRow:DIAMETER column:i];
	[self velumMatrixEntered:velumMatrix];
    }

    /*  INITIALIZE ORAL DISPLAY  */
    for (i = 0; i < 2; i++) {
	[[oralMatrix1 cellAtRow:DIAMETER column:i] setDoubleValue:oralDiameter[i]];
	[oralMatrix1 selectCellAtRow:DIAMETER column:i];
	[self oralMatrix1Entered:oralMatrix1];
    }
    for (i = 2; i < ORAL_REGIONS; i++) {
	[[oralMatrix2 cellAtRow:DIAMETER column:(i-2)] setDoubleValue:oralDiameter[i]];
	[oralMatrix2 selectCellAtRow:DIAMETER column:(i-2)];
	[self oralMatrix2Entered:oralMatrix2];
    }

    /*  INITIALIZE NASAL DISPLAY  */
    for (i = 0; i < NASAL_REGIONS; i++) {
	[[nasalMatrix cellAtRow:DIAMETER column:i] setDoubleValue:nasalDiameter[i]];
	[nasalMatrix selectCellAtRow:DIAMETER column:i];
	[self nasalMatrixEntered:nasalMatrix];
    }

    /*  INITIALIZE JUNCTION LOSS FACTOR DISPLAY  */
    [lossFactorSlider setDoubleValue:(lossFactor * 100.0)];
    [self lossFactorSliderMoved:lossFactorSlider];

    /*  INITIALIZE APERTURE SCALING DISPLAY  */
    [[apertureMatrix cellAtRow:DIAMETER column:0] setDoubleValue:apertureScaling];
    [apertureMatrix selectCellAtRow:DIAMETER column:0];
    [self apertureMatrixEntered:apertureMatrix];

    /*  INITIALIZE FREQUENCY RESPONSE SCALE SWITCHES  */
    [mouthSwitch selectCellWithTag:mouthResponseScale];
    [noseSwitch selectCellWithTag:noseResponseScale];

    /*  INITIALIZE MOUTH FILTER DISPLAY  */
    [mouthFilterSlider setDoubleValue:mouthFilterCoefficient];
    [mouthFilterField setDoubleValue:mouthFilterCoefficient];
    [mouthFrequencyResponse drawFrequencyResponse:mouthFilterCoefficient sampleRate:sampleRate scale:mouthResponseScale];
    [synthesizer setMouthFilterCoefficient:mouthFilterCoefficient];

    /*  INITIALIZE NOSE FILTER DISPLAY  */
    [noseFilterSlider setDoubleValue:noseFilterCoefficient];
    [noseFilterField setDoubleValue:noseFilterCoefficient];
    [self noseFilterSliderMoved:noseFilterSlider];
    [noseFrequencyResponse drawFrequencyResponse:noseFilterCoefficient sampleRate:sampleRate scale:noseResponseScale];
    [synthesizer setNoseFilterCoefficient:noseFilterCoefficient];

    /*  INITIALIZE LENGTH DISPLAY  */
    [lengthField setDoubleValue:length];
    [self lengthFieldEntered:lengthField];

    /*  INITIALIZE TEMPERATURE DISPLAY  */
    [temperatureField setDoubleValue:temperature];
    [self temperatureFieldEntered:temperatureField];

    /*  INITIALIZE MISC. DISPLAY  */
    [self adjustSampleRate];

    /*  DRAW ARROW WHERE FRICATION IS TO BE INJECTED  */
    [positionView drawPosition:[noiseSource fricationPosition]];

    /*  DISPLAY CHANGES TO SUBVIEWS OF WINDOW  */
    [resonantSystemWindow displayIfNeeded]; 
}



- (void)saveToStream:(NSArchiver *)typedStream
{
    /*  WRITE INSTANCE VARIABLES TO TYPED STREAM  */
    [typedStream encodeArrayOfObjCType:"d" count:PHARYNX_REGIONS at:pharynxDiameter];
    [typedStream encodeArrayOfObjCType:"d" count:VELUM_REGIONS at:velumDiameter];
    [typedStream encodeArrayOfObjCType:"d" count:ORAL_REGIONS at:oralDiameter];
    [typedStream encodeArrayOfObjCType:"d" count:NASAL_REGIONS at:nasalDiameter];
    [typedStream encodeValuesOfObjCTypes:"ddddiiddddi", &lossFactor, &apertureScaling,
		 &mouthFilterCoefficient, &noseFilterCoefficient,
		 &mouthResponseScale, &noseResponseScale, &temperature,
		 &length, &sampleRate, &actualLength, &controlPeriod]; 
}



- (void)openFromStream:(NSArchiver *)typedStream
{
    /*  READ INSTANCE VARIABLES FROM TYPED STREAM  */
    [typedStream decodeArrayOfObjCType:"d" count:PHARYNX_REGIONS at:pharynxDiameter];
    [typedStream decodeArrayOfObjCType:"d" count:VELUM_REGIONS at:velumDiameter];
    [typedStream decodeArrayOfObjCType:"d" count:ORAL_REGIONS at:oralDiameter];
    [typedStream decodeArrayOfObjCType:"d" count:NASAL_REGIONS at:nasalDiameter];
    [typedStream decodeValuesOfObjCTypes:"ddddiiddddi", &lossFactor, &apertureScaling,
		&mouthFilterCoefficient, &noseFilterCoefficient,
		&mouthResponseScale, &noseResponseScale, &temperature,
		&length, &sampleRate, &actualLength, &controlPeriod];

    /*  DISPLAY THE NEW VALUES  */
    [self displayAndSynthesizeIvars]; 
}


#ifdef NeXT
- (void)_openFromStream:(NXTypedStream *)typedStream
{
    /*  READ INSTANCE VARIABLES FROM TYPED STREAM  */
    NXReadArray(typedStream, "d", PHARYNX_REGIONS, pharynxDiameter);
    NXReadArray(typedStream, "d", VELUM_REGIONS, velumDiameter);
    NXReadArray(typedStream, "d", ORAL_REGIONS, oralDiameter);
    NXReadArray(typedStream, "d", NASAL_REGIONS, nasalDiameter);
    NXReadTypes(typedStream, "ddddiiddddi", &lossFactor, &apertureScaling,
		&mouthFilterCoefficient, &noseFilterCoefficient,
		&mouthResponseScale, &noseResponseScale, &temperature,
		&length, &sampleRate, &actualLength, &controlPeriod);

    /*  DISPLAY THE NEW VALUES  */
    [self displayAndSynthesizeIvars]; 
}
#endif



- (void)pharynxSectionMoved:sender
{
    int tag;
    double diameter;

    /*  GET THE VALUE OF THE SLIDER (STRING VALUE USES FIXED FORMAT)  */
    diameter = atof([[sender stringValue] cString]);

    /*  GET THE TAG OF THE SLIDER  */
    tag = [sender tag];

    /*  DEAL WITH VALUE ONLY IF IT DIFFERS FROM PREVIOUS VALUE  */
    if (pharynxDiameter[tag] != diameter) {
	double radius = diameter / 2.0;
	double area = PI * radius * radius;

	/*  SET DIAMETER INSTANCE VARIABLE  */
	pharynxDiameter[tag] = diameter;

	/*  SET DIAMETER IN MATRIX  */
	[[pharynxMatrix cellAtRow:DIAMETER column:tag] setDoubleValue:diameter];

	/*  SET RADIUS IN MATRIX  */
	[[pharynxMatrix cellAtRow:RADIUS column:tag] setDoubleValue:radius];

	/*  SET AREA IN MATRIX  */
	[[pharynxMatrix cellAtRow:AREA column:tag] setDoubleValue:area];

	/*  SEND NEW DIAMETER TO SYNTHESIZER  */
	[synthesizer setPharynxSection:tag toDiameter:pharynxDiameter[tag]];

	/*  SET DIRTY BIT  */
	[controller setDirtyBit];
    } 
}

- (void)pharynxMatrixEntered:sender
{
    int column, row;
    BOOL rangeError = NO;
    double diameter = 0.0, area = 0.0;


    /*  GET ROW AND COLUMN NUMBERS OF TEXT CELL  */
    column = [sender selectedColumn];
    row = [sender selectedRow];

    /*  DETERMINE EQUIVALENT DIAMETER VALUE  */
    switch (row) {
      case RADIUS:
	diameter = 2.0 * [sender doubleValue];
	break;
      case DIAMETER:
	diameter = [sender doubleValue];
	break;
      case AREA:
	if ((area = [sender doubleValue]) < 0.0) {
	    rangeError = YES;
	    diameter = 0.0;
	    break;
	}
	else {
	    diameter = 2.0 * sqrt(area/PI);
	    break;
	}
      default:
	diameter = DIAMETER_MIN;
	break;
    }

    /*  CORRECT OUT OF RANGE VALUES  */
    if (diameter < DIAMETER_MIN) {
	diameter = DIAMETER_MIN;
	rangeError = YES;
    }
    else if (diameter > DIAMETER_MAX) {
	diameter = DIAMETER_MAX;
	rangeError = YES;
    }
    
    /*  SET THE IVAR, AREA SLIDER, SYNTHESIZER, AND EQUIVALENT MATRIX
	VALUES BY FORCING THE SECTION MOVED METHOD  */
    pharynxDiameter[column] = -1;
    switch (column) {
      case 0:
	[pharynxSection1 setFloatValue:diameter];
	[self pharynxSectionMoved:pharynxSection1];
	break;
      case 1:
	[pharynxSection2 setFloatValue:diameter];
	[self pharynxSectionMoved:pharynxSection2];
	break;
      case 2:
	[pharynxSection3 setFloatValue:diameter];
	[self pharynxSectionMoved:pharynxSection3];
	break;
      default:
	break;
    }

    /*  IF RANGE ERROR, BEEP & SELECT THE OUT OF RANGE CELL  */
    if (rangeError) {
	NSBeep();
	[sender selectTextAtRow:row column:column];
    }
    /*  ELSE, SELECT THE CELL IN THE NEXT COLUMN  */
    else {
	if (++column >= PHARYNX_REGIONS)
	    [oralMatrix1 selectTextAtRow:row column:0];
	else
	    [sender selectTextAtRow:row column:column];
    } 
}



- (void)velumSectionMoved:sender
{
    int tag;
    double diameter;

    /*  GET THE VALUE OF THE SLIDER (STRING VALUE USES FIXED FORMAT)  */
    diameter = atof([[sender stringValue] cString]);

    /*  GET THE TAG OF THE SLIDER  */
    tag = [sender tag];

    /*  DEAL WITH VALUE ONLY IF IT DIFFERS FROM PREVIOUS VALUE  */
    if (velumDiameter[tag] != diameter) {
	double radius = diameter / 2.0;
	double area = PI * radius * radius;

	/*  SET DIAMETER INSTANCE VARIABLE  */
	velumDiameter[tag] = diameter;

	/*  SET DIAMETER IN MATRIX  */
	[[velumMatrix cellAtRow:DIAMETER column:tag] setDoubleValue:diameter];

	/*  SET RADIUS IN MATRIX  */
	[[velumMatrix cellAtRow:RADIUS column:tag] setDoubleValue:radius];

	/*  SET AREA IN MATRIX  */
	[[velumMatrix cellAtRow:AREA column:tag] setDoubleValue:area];

	/*  SEND NEW DIAMETER TO SYNTHESIZER  */
	[synthesizer setVelumSection:tag toDiameter:velumDiameter[tag]];

	/*  SET DIRTY BIT  */
	[controller setDirtyBit];
    } 
}

- (void)velumMatrixEntered:sender
{
    int column, row;
    BOOL rangeError = NO;
    double diameter = 0.0, area = 0.0;


    /*  GET ROW AND COLUMN NUMBERS OF TEXT CELL  */
    column = [sender selectedColumn];
    row = [sender selectedRow];

    /*  DETERMINE EQUIVALENT DIAMETER VALUE  */
    switch (row) {
      case RADIUS:
	diameter = 2.0 * [sender doubleValue];
	break;
      case DIAMETER:
	diameter = [sender doubleValue];
	break;
      case AREA:
	if ((area = [sender doubleValue]) < 0.0) {
	    rangeError = YES;
	    diameter = 0.0;
	    break;
	}
	else {
	    diameter = 2.0 * sqrt(area/PI);
	    break;
	}
      default:
	diameter = DIAMETER_MIN;
	break;
    }

    /*  CORRECT OUT OF RANGE VALUES  */
    if (diameter < DIAMETER_MIN) {
	diameter = DIAMETER_MIN;
	rangeError = YES;
    }
    else if (diameter > VELUM_DIAMETER_MAX) {
	diameter = VELUM_DIAMETER_MAX;
	rangeError = YES;
    }
    
    /*  SET THE IVAR, AREA SLIDER, SYNTHESIZER, AND EQUIVALENT MATRIX
	VALUES BY FORCING THE SECTION MOVED METHOD  */
    velumDiameter[column] = -1;
    switch (column) {
      case 0:
	[velumSection setFloatValue:diameter];
	[self velumSectionMoved:velumSection];
	break;
      default:
	break;
    }

    /*  IF RANGE ERROR, BEEP & SELECT THE OUT OF RANGE CELL  */
    if (rangeError) {
	NSBeep();
	[sender selectTextAtRow:row column:column];
    }
    /*  ELSE, SELECT THE CELL IN THE NEXT COLUMN  */
    else {
	if (++column >= VELUM_REGIONS)
	    [nasalMatrix selectTextAtRow:row column:0];
	else
	    [sender selectTextAtRow:row column:column];
    } 
}



- (void)oralSectionMoved:sender
{
    int tag;
    double diameter;

    /*  GET THE VALUE OF THE SLIDER (STRING VALUE USES FIXED FORMAT)  */
    diameter = atof([[sender stringValue] cString]);

    /*  GET THE TAG OF THE SLIDER  */
    tag = [sender tag];

    /*  DEAL WITH VALUE ONLY IF IT DIFFERS FROM PREVIOUS VALUE  */
    if (oralDiameter[tag] != diameter) {
	double radius = diameter / 2.0;
	double area = PI * radius * radius;

	/*  SET DIAMETER INSTANCE VARIABLE  */
	oralDiameter[tag] = diameter;

	/*  SET DIAMETER IN MATRIX1 OR 2  */
	if (tag < 2)
	    [[oralMatrix1 cellAtRow:DIAMETER column:tag] setDoubleValue:diameter];
	else
	    [[oralMatrix2 cellAtRow:DIAMETER column:(tag-2)] setDoubleValue:diameter];

	/*  SET RADIUS IN MATRIX1 OR 2  */
	if (tag < 2)
	    [[oralMatrix1 cellAtRow:RADIUS column:tag] setDoubleValue:radius];
	else
	    [[oralMatrix2 cellAtRow:RADIUS column:(tag-2)] setDoubleValue:radius];

	/*  SET AREA IN MATRIX1 OR 2  */
	if (tag < 2)
	    [[oralMatrix1 cellAtRow:AREA column:tag] setDoubleValue:area];
	else
	    [[oralMatrix2 cellAtRow:AREA column:(tag-2)] setDoubleValue:area];

	/*  SEND NEW DIAMETER TO SYNTHESIZER  */
	[synthesizer setOralSection:tag toDiameter:oralDiameter[tag]];

	/*  SET DIRTY BIT  */
	[controller setDirtyBit];
    } 
}

- (void)oralMatrix1Entered:sender
{
    int column, row;
    BOOL rangeError = NO;
    double diameter = 0.0, area = 0.0;


    /*  GET ROW AND COLUMN NUMBERS OF TEXT CELL  */
    column = [sender selectedColumn];
    row = [sender selectedRow];

    /*  DETERMINE EQUIVALENT DIAMETER VALUE  */
    switch (row) {
      case RADIUS:
	diameter = 2.0 * [sender doubleValue];
	break;
      case DIAMETER:
	diameter = [sender doubleValue];
	break;
      case AREA:
	if ((area = [sender doubleValue]) < 0.0) {
	    rangeError = YES;
	    diameter = 0.0;
	    break;
	}
	else {
	    diameter = 2.0 * sqrt(area/PI);
	    break;
	}
      default:
	diameter = DIAMETER_MIN;
	break;
    }

    /*  CORRECT OUT OF RANGE VALUES  */
    if (diameter < DIAMETER_MIN) {
	diameter = DIAMETER_MIN;
	rangeError = YES;
    }
    else if (diameter > DIAMETER_MAX) {
	diameter = DIAMETER_MAX;
	rangeError = YES;
    }
    
    /*  SET THE IVAR, AREA SLIDER, SYNTHESIZER, AND EQUIVALENT MATRIX
	VALUES BY FORCING THE SECTION MOVED METHOD  */
    oralDiameter[column] = -1;
    switch (column) {
      case 0:
	[oralSection1 setFloatValue:diameter];
	[self oralSectionMoved:oralSection1];
	break;
      case 1:
	[oralSection2 setFloatValue:diameter];
	[self oralSectionMoved:oralSection2];
	break;
      default:
	break;
    }

    /*  IF RANGE ERROR, BEEP & SELECT THE OUT OF RANGE CELL  */
    if (rangeError) {
	NSBeep();
	[sender selectTextAtRow:row column:column];
    }
    /*  ELSE, SELECT THE CELL IN THE NEXT COLUMN  */
    else {
	if (++column >= 2)
	    [oralMatrix2 selectTextAtRow:row column:0];
	else
	    [sender selectTextAtRow:row column:column];
    } 
}

- (void)oralMatrix2Entered:sender
{
    int column, row;
    BOOL rangeError = NO;
    double diameter = 0.0, area = 0.0;


    /*  GET ROW AND COLUMN NUMBERS OF TEXT CELL  */
    column = [sender selectedColumn];
    row = [sender selectedRow];

    /*  DETERMINE EQUIVALENT DIAMETER VALUE  */
    switch (row) {
      case RADIUS:
	diameter = 2.0 * [sender doubleValue];
	break;
      case DIAMETER:
	diameter = [sender doubleValue];
	break;
      case AREA:
	if ((area = [sender doubleValue]) < 0.0) {
	    rangeError = YES;
	    diameter = 0.0;
	    break;
	}
	else {
	    diameter = 2.0 * sqrt(area/PI);
	    break;
	}
      default:
	diameter = DIAMETER_MIN;
	break;
    }

    /*  CORRECT OUT OF RANGE VALUES  */
    if (diameter < DIAMETER_MIN) {
	diameter = DIAMETER_MIN;
	rangeError = YES;
    }
    else if (diameter > DIAMETER_MAX) {
	diameter = DIAMETER_MAX;
	rangeError = YES;
    }
    
    /*  SET THE IVAR, AREA SLIDER, SYNTHESIZER, AND EQUIVALENT MATRIX
	VALUES BY FORCING THE SECTION MOVED METHOD  */
    oralDiameter[column+2] = -1;
    switch (column) {
      case 0:
	[oralSection3 setFloatValue:diameter];
	[self oralSectionMoved:oralSection3];
	break;
      case 1:
	[oralSection4 setFloatValue:diameter];
	[self oralSectionMoved:oralSection4];
	break;
      case 2:
	[oralSection5 setFloatValue:diameter];
	[self oralSectionMoved:oralSection5];
	break;
      default:
	break;
    }

    /*  IF RANGE ERROR, BEEP & SELECT THE OUT OF RANGE CELL  */
    if (rangeError) {
	NSBeep();
	[sender selectTextAtRow:row column:column];
    }
    /*  ELSE, SELECT THE CELL IN THE NEXT COLUMN  */
    else {
	if (++column >= 3)
	    [velumMatrix selectTextAtRow:row column:0];
	else
	    [sender selectTextAtRow:row column:column];
    } 
}



- (void)nasalSectionMoved:sender
{
    int tag;
    double diameter;

    /*  GET THE VALUE OF THE SLIDER (STRING VALUE USES FIXED FORMAT)  */
    diameter = atof([[sender stringValue] cString]);

    /*  GET THE TAG OF THE SLIDER  */
    tag = [sender tag];

    /*  DEAL WITH VALUE ONLY IF IT DIFFERS FROM PREVIOUS VALUE  */
    if (nasalDiameter[tag] != diameter) {
	double radius = diameter / 2.0;
	double area = PI * radius * radius;

	/*  SET DIAMETER INSTANCE VARIABLE  */
	nasalDiameter[tag] = diameter;

	/*  SET DIAMETER IN MATRIX  */
	[[nasalMatrix cellAtRow:DIAMETER column:tag] setDoubleValue:diameter];

	/*  SET RADIUS IN MATRIX  */
	[[nasalMatrix cellAtRow:RADIUS column:tag] setDoubleValue:radius];

	/*  SET AREA IN MATRIX  */
	[[nasalMatrix cellAtRow:AREA column:tag] setDoubleValue:area];

	/*  SEND NEW DIAMETER TO SYNTHESIZER  */
	[synthesizer setNasalSection:tag toDiameter:nasalDiameter[tag]];

	/*  SET DIRTY BIT  */
	[controller setDirtyBit];
    } 
}

- (void)nasalMatrixEntered:sender
{
    int column, row;
    BOOL rangeError = NO;
    double diameter = 0.0, area = 0.0;


    /*  GET ROW AND COLUMN NUMBERS OF TEXT CELL  */
    column = [sender selectedColumn];
    row = [sender selectedRow];

    /*  DETERMINE EQUIVALENT DIAMETER VALUE  */
    switch (row) {
      case RADIUS:
	diameter = 2.0 * [sender doubleValue];
	break;
      case DIAMETER:
	diameter = [sender doubleValue];
	break;
      case AREA:
	if ((area = [sender doubleValue]) < 0.0) {
	    rangeError = YES;
	    diameter = 0.0;
	    break;
	}
	else {
	    diameter = 2.0 * sqrt(area/PI);
	    break;
	}
      default:
	diameter = DIAMETER_MIN;
	break;
    }

    /*  CORRECT OUT OF RANGE VALUES  */
    if (diameter < DIAMETER_MIN) {
	diameter = DIAMETER_MIN;
	rangeError = YES;
    }
    else if (diameter > DIAMETER_MAX) {
	diameter = DIAMETER_MAX;
	rangeError = YES;
    }
    
    /*  SET THE IVAR, AREA SLIDER, SYNTHESIZER, AND EQUIVALENT MATRIX
	VALUES BY FORCING THE SECTION MOVED METHOD  */
    nasalDiameter[column] = -1;
    switch (column) {
      case 0:
	[nasalSection1 setFloatValue:diameter];
	[self nasalSectionMoved:nasalSection1];
	break;
      case 1:
	[nasalSection2 setFloatValue:diameter];
	[self nasalSectionMoved:nasalSection2];
	break;
      case 2:
	[nasalSection3 setFloatValue:diameter];
	[self nasalSectionMoved:nasalSection3];
	break;
      case 3:
	[nasalSection4 setFloatValue:diameter];
	[self nasalSectionMoved:nasalSection4];
	break;
      case 4:
	[nasalSection5 setFloatValue:diameter];
	[self nasalSectionMoved:nasalSection5];
	break;
      default:
	break;
    }

    /*  IF RANGE ERROR, BEEP & SELECT THE OUT OF RANGE CELL  */
    if (rangeError) {
	NSBeep();
	[sender selectTextAtRow:row column:column];
    }
    /*  ELSE, SELECT THE CELL IN THE NEXT COLUMN  */
    else {
	if (++column >= NASAL_REGIONS)
	    [pharynxMatrix selectTextAtRow:row column:0];
	else
	    [sender selectTextAtRow:row column:column];
    } 
}



- (void)lengthSliderMoved:sender
{
    /*  GET CURRENT VALUE (STRING VALUE USES FIXED FORMAT)  */
    double currentValue = atof([[sender stringValue] cString]);

    /*  IF CURRENT VALUE IS DIFFERENT FROM PREVIOUS VALUE, DEAL WITH IT  */
    if (currentValue != length) {
	/*  SET INSTANCE VARIABLE  */
	length = currentValue;

	/*  SET FIELD DISPLAY  */
	[lengthField setDoubleValue:length];

	/*  SET SAMPLING RATE, ETC. (THIS SENDS VALUES TO SYNTH)  */
	[self adjustSampleRate];
    } 
}

- (void)lengthFieldEntered:sender
{
    BOOL rangeError = NO;

    /*  GET THE CURRENT VALUE (STRING VALUE USES FIXED FORMAT)  */
    double currentValue = atof([[sender stringValue] cString]);

    /*  MAKE SURE VALUE IS IN RANGE  */
    if (currentValue < LENGTH_MIN) {
	rangeError = YES;
	currentValue = LENGTH_MIN;
    }
    else if (currentValue > LENGTH_MAX) {
	rangeError = YES;
	currentValue = LENGTH_MAX;
    }

    /*  INVOKE SLIDER METHOD TO SET SLIDER  */
    [lengthSlider setDoubleValue:currentValue];
    [self lengthSliderMoved:lengthSlider];

    /*  BEEP AND HIGHLIGHT FIELD IF RANGE ERROR  */
    if (rangeError) {
	NSBeep();
	[lengthField selectText:self];
    } 
}



- (void)temperatureSliderMoved:sender
{
    /*  GET CURRENT VALUE (STRING VALUE USES FIXED FORMAT)  */
    double currentValue = atof([[sender stringValue] cString]);

    /*  IF CURRENT VALUE IS DIFFERENT FROM PREVIOUS VALUE, DEAL WITH IT  */
    if (currentValue != temperature) {
	/*  SET INSTANCE VARIABLE  */
	temperature = currentValue;

	/*  SET FIELD DISPLAY  */
	[temperatureField setDoubleValue:temperature];

	/*  SET SAMPLING RATE, ETC. (THIS SENDS VALUES TO SYNTH)  */
	[self adjustSampleRate];
    } 
}

- (void)temperatureFieldEntered:sender
{
    BOOL rangeError = NO;

    /*  GET THE CURRENT VALUE (STRING VALUE USES FIXED FORMAT)  */
    double currentValue = atof([[sender stringValue] cString]);

    /*  MAKE SURE VALUE IS IN RANGE  */
    if (currentValue < TEMPERATURE_MIN) {
	rangeError = YES;
	currentValue = TEMPERATURE_MIN;
    }
    else if (currentValue > TEMPERATURE_MAX) {
	rangeError = YES;
	currentValue = TEMPERATURE_MAX;
    }

    /*  INVOKE SLIDER METHOD TO SET SLIDER  */
    [temperatureSlider setDoubleValue:currentValue];
    [self temperatureSliderMoved:temperatureSlider];

    /*  BEEP AND HIGHLIGHT FIELD IF RANGE ERROR  */
    if (rangeError) {
	NSBeep();
	[temperatureField selectText:self];
    } 
}



- (void)lossFactorSliderMoved:sender
{
    double currentValue;

    /*  SET FIELD DISPLAY  */
    [lossFactorField setDoubleValue:[sender doubleValue]];
    
    /*  GET CURRENT VALUE (FIELD USES FIXED FORMAT)  */
    currentValue = [lossFactorField doubleValue] / 100.0;

    /*  IF CURRENT VALUE IS DIFFERENT FROM PREVIOUS VALUE, DEAL WITH IT  */
    if (currentValue != lossFactor) {
	/*  SET INSTANCE VARIABLE  */
	lossFactor = currentValue;

	/*  SET DAMPING FACTOR FIELD DISPLAY  */
	[dampingFactorField setDoubleValue:((1.0 - lossFactor) * 100.0)];

	/*  SEND VALUE TO SYNTHESIZER  */
	[synthesizer setDampingFactor:(1.0 - lossFactor)];

	/*  SET DIRTY BIT  */
	[controller setDirtyBit];
    } 
}

- (void)lossFactorFieldEntered:sender
{
    BOOL rangeError = NO;

    /*  GET THE CURRENT VALUE  */
    double currentValue = [sender doubleValue];

    /*  MAKE SURE VALUE IS IN RANGE  */
    if (currentValue < LOSS_FACTOR_MIN) {
	rangeError = YES;
	currentValue = LOSS_FACTOR_MIN;
    }
    else if (currentValue > LOSS_FACTOR_MAX) {
	rangeError = YES;
	currentValue = LOSS_FACTOR_MAX;
    }

    /*  INVOKE SLIDER METHOD TO SET SLIDER AND DAMPING FIELD  */
    [lossFactorSlider setDoubleValue:currentValue];
    [self lossFactorSliderMoved:lossFactorSlider];

    /*  BEEP AND HIGHLIGHT FIELD IF RANGE ERROR  */
    if (rangeError) {
	NSBeep();
	[lossFactorField selectText:self];
    } 
}



- (void)apertureMatrixEntered:sender
{
    int column, row;
    BOOL rangeError = NO;
    double radius = 0.0, diameter = 0.0, area = 0.0;


    /*  GET ROW AND COLUMN NUMBERS OF TEXT CELL  */
    column = [sender selectedColumn];
    row = [sender selectedRow];

    /*  DETERMINE EQUIVALENT DIAMETER VALUE  */
    switch (row) {
      case RADIUS:
	diameter = 2.0 * atof([[sender stringValue] cString]);
	break;
      case DIAMETER:
	diameter = atof([[sender stringValue] cString]);
	break;
      case AREA:
	if ((area = atof([[sender stringValue] cString])) < 0.0) {
	    rangeError = YES;
	    diameter = APERTURE_SCALING_MIN;
	    break;
	}
	else {
	    diameter = 2.0 * sqrt(area/PI);
	    break;
	}
      default:
	diameter = APERTURE_SCALING_MIN;
	break;
    }

    /*  CORRECT OUT OF RANGE VALUES  */
    if (diameter < APERTURE_SCALING_MIN) {
	diameter = APERTURE_SCALING_MIN;
	rangeError = YES;
    }
    else if (diameter > APERTURE_SCALING_MAX) {
	diameter = APERTURE_SCALING_MAX;
	rangeError = YES;
    }
    
    /*  SET THE INSTANCE VARIABLE  */
    apertureScaling = diameter;

    /*  SET EQUIVALENT MATRIX VALUES  */
    [[sender cellAtRow:RADIUS column:0] setDoubleValue:(apertureScaling/2.0)];
    [[sender cellAtRow:DIAMETER column:0] setDoubleValue:apertureScaling];
    radius = apertureScaling / 2.0;
    [[sender cellAtRow:AREA column:0] setDoubleValue:(PI * radius * radius)];

    /*  SEND VALUE TO SYNTHESIZER  */
    [synthesizer setApertureScaling:apertureScaling];
    
    /*  SET DIRTY BIT  */
    [controller setDirtyBit];

    /*  IF RANGE ERROR, BEEP & SELECT THE OUT OF RANGE CELL  */
    if (rangeError) {
	NSBeep();
	[sender selectTextAtRow:row column:column];
    } 
}



- (void)mouthSwitchPushed:sender
{
    /*  GET VALUE FROM STATE OF BUTTON  */
    int selectedValue = [[sender selectedCell] tag];

    /*  PROCESS ONLY IF NEW VALUE  */
    if (selectedValue != mouthResponseScale) {
	mouthResponseScale = selectedValue;

	/*  REDISPLAY FREQUENCY RESPONSE  */	
	[mouthFrequencyResponse drawFrequencyResponse:mouthFilterCoefficient sampleRate:sampleRate scale:mouthResponseScale];

	/*  SET DIRTY BIT  */
	[controller setDirtyBit];
    } 
}



- (void)noseSwitchPushed:sender
{
    /*  GET VALUE FROM STATE OF BUTTON  */
    int selectedValue = [[sender selectedCell] tag];

    /*  PROCESS ONLY IF NEW VALUE  */
    if (selectedValue != noseResponseScale) {
	noseResponseScale = selectedValue;

	/*  REDISPLAY FREQUENCY RESPONSE  */	
	[noseFrequencyResponse drawFrequencyResponse:noseFilterCoefficient sampleRate:sampleRate scale:noseResponseScale];

	/*  SET DIRTY BIT  */
	[controller setDirtyBit];
    } 
}



- (void)mouthFilterFieldEntered:sender
{
    BOOL rangeError = NO;

    /*  GET THE CURRENT VALUE  */
    double currentValue = [sender doubleValue];

    /*  MAKE SURE VALUE IS IN RANGE  */
    if (currentValue < APERTURE_COEF_MIN) {
	rangeError = YES;
	currentValue = APERTURE_COEF_MIN;
    }
    else if (currentValue > sampleRate/2.0) {
	rangeError = YES;
	currentValue = sampleRate/2.0;
    }

    /*  INVOKE SLIDER METHOD TO SET SLIDER AND DAMPING FIELD  */
    [mouthFilterSlider setDoubleValue:currentValue];
    [self mouthFilterSliderMoved:mouthFilterSlider];

    /*  BEEP AND HIGHLIGHT FIELD IF RANGE ERROR  */
    if (rangeError) {
	NSBeep();
	[mouthFilterField selectText:self];
    } 
}



- (void)mouthFilterSliderMoved:sender
{
    double currentValue;

    /*  SET FIELD DISPLAY  */
    [mouthFilterField setDoubleValue:[sender doubleValue]];
    
    /*  GET CURRENT VALUE (FIELD USES FIXED FORMAT)  */
    currentValue = [mouthFilterField doubleValue];

    /*  IF CURRENT VALUE IS DIFFERENT FROM PREVIOUS VALUE, DEAL WITH IT  */
    if (currentValue != mouthFilterCoefficient) {
	/*  SET INSTANCE VARIABLE  */
	mouthFilterCoefficient = currentValue;

	/*  DISPLAY FREQUENCY RESPONSE OF THE MOUTH FILTERS  */
	[mouthFrequencyResponse drawFrequencyResponse:mouthFilterCoefficient sampleRate:sampleRate scale:mouthResponseScale];

	/*  SEND VALUE TO SYNTHESIZER  */
	[synthesizer setMouthFilterCoefficient:mouthFilterCoefficient];

	/*  SET DIRTY BIT  */
	[controller setDirtyBit];
    } 
}



- (void)noseFilterFieldEntered:sender
{
    BOOL rangeError = NO;

    /*  GET THE CURRENT VALUE  */
    double currentValue = [sender doubleValue];

    /*  MAKE SURE VALUE IS IN RANGE  */
    if (currentValue < APERTURE_COEF_MIN) {
	rangeError = YES;
	currentValue = APERTURE_COEF_MIN;
    }
    else if (currentValue > sampleRate/2.0) {
	rangeError = YES;
	currentValue = sampleRate/2.0;
    }

    /*  INVOKE SLIDER METHOD TO SET SLIDER AND DAMPING FIELD  */
    [noseFilterSlider setDoubleValue:currentValue];
    [self noseFilterSliderMoved:noseFilterSlider];

    /*  BEEP AND HIGHLIGHT FIELD IF RANGE ERROR  */
    if (rangeError) {
	NSBeep();
	[noseFilterField selectText:self];
    } 
}



- (void)noseFilterSliderMoved:sender
{
    double currentValue;

    /*  SET FIELD DISPLAY  */
    [noseFilterField setDoubleValue:[sender doubleValue]];
    
    /*  GET CURRENT VALUE (FIELD USES FIXED FORMAT)  */
    currentValue = [noseFilterField doubleValue];

    /*  IF CURRENT VALUE IS DIFFERENT FROM PREVIOUS VALUE, DEAL WITH IT  */
    if (currentValue != noseFilterCoefficient) {
	/*  SET INSTANCE VARIABLE  */
	noseFilterCoefficient = currentValue;

	/*  DISPLAY FREQUENCY RESPONSE OF THE NOSE FILTERS  */
	[noseFrequencyResponse drawFrequencyResponse:noseFilterCoefficient sampleRate:sampleRate scale:noseResponseScale];

	/*  SEND VALUE TO SYNTHESIZER  */
	[synthesizer setNoseFilterCoefficient:noseFilterCoefficient];

	/*  SET DIRTY BIT  */
	[controller setDirtyBit];
    } 
}



- (void)adjustToNewSampleRate
{
    int nyquistFrequency;

    /* CALCULATE NYQUIST FREQUENCY  */
    nyquistFrequency = (int)rint(sampleRate / 2.0);

    /*  SET THE MAXIMUM FOR THE SLIDERS  */
    [mouthFilterSlider setMaxValue:nyquistFrequency];
    [noseFilterSlider setMaxValue:nyquistFrequency];

    /*  CHANGE MOUTH FILTER COEFFICIENT, IF NECESSARY  */
    if (mouthFilterCoefficient > nyquistFrequency) {
	 mouthFilterCoefficient = nyquistFrequency;
	
	 /*  RE-INITIALIZE MOUTH FILTER OBJECTS  */
	 [mouthFilterSlider setDoubleValue:mouthFilterCoefficient];
	 [mouthFilterField setDoubleValue:mouthFilterCoefficient];
	 [synthesizer setMouthFilterCoefficient:mouthFilterCoefficient];
    }

    /*  CHANGE NOSE FILTER COEFFICIENT, IF NECESSARY  */
    if (noseFilterCoefficient > nyquistFrequency) {
	 noseFilterCoefficient = nyquistFrequency;
	
	 /*  RE-INITIALIZE NOSE FILTER OBJECTS  */
	 [noseFilterSlider setDoubleValue:noseFilterCoefficient];
	 [noseFilterField setDoubleValue:noseFilterCoefficient];
	 [synthesizer setNoseFilterCoefficient:noseFilterCoefficient];
    }

    /*  RE-DISPLAY APERTURE FREQUENCY RESPONSES  */
    [mouthFrequencyResponse drawFrequencyResponse:mouthFilterCoefficient sampleRate:sampleRate scale:mouthResponseScale];
    [noseFrequencyResponse drawFrequencyResponse:noseFilterCoefficient sampleRate:sampleRate scale:noseResponseScale]; 
}



- (void)adjustSampleRate
{
    /*  CALCULATE SAMPLE RATE, CONTROL PERIOD, ACTUAL LENGTH  */
    [self calculateSampleRate];

    /*  DISPLAY THESE VALUES  */
    [actualLengthField setDoubleValue:actualLength];
    [sampleRateField setDoubleValue:sampleRate];
    [controlPeriodField setIntValue:controlPeriod];

    /*  REDISPLAY APERTURE, NOISE SOURCE, AND THROAT FREQUENCY RESPONSES  */
    [self adjustToNewSampleRate];
    [noiseSource adjustToNewSampleRate];
    [throat adjustToNewSampleRate];

    /*  SEND APPROPRIATE VALUES TO THE SYNTHESIZER  */
    [synthesizer setActualLength:actualLength sampleRate:sampleRate controlPeriod:controlPeriod];
    
    /*  SET DIRTY BIT  */
    [controller setDirtyBit]; 
}



- (double)sampleRate
{
    return sampleRate;
}


- (void)injectFricationAt:(float)position
{
    /*  DRAW ARROW WHERE FRICATION IS TO BE INJECTED  */
    [positionView drawPosition:position]; 
}



- (void)windowWillMiniaturize:sender
{
    [sender setMiniwindowTitle:@"Resonance"];
    [sender setMiniwindowImage:[NSImage imageNamed:@"Synthesizer.tiff"]];
}



- (void)setTitle:(NSString *)path
{
    [resonantSystemWindow setTitleWithRepresentedFilename:path];
}



/******************************************************************************
*
*       function:       speedOfSound
*
*       purpose:        Returns the speed of sound according to the value of
*                       the temperature (in Celsius degrees).
*
*       arguments:      temperature
*
*       internal
*       functions:      none
*
*       library
*       functions:      none
*
******************************************************************************/

double speedOfSound(double temperature)
{
  return (331.4 + (0.6 * temperature));
}

@end
