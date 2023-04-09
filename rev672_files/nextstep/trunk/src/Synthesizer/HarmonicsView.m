/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/HarmonicsView.m,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

# Revision 1.1.1.1  1994/05/20  00:21:45  len
# Initial archive of TRM interactive Synthesizer.
#

******************************************************************************/


/*  HEADER FILES  ************************************************************/
#import "HarmonicsView.h"
#import "PSwraps.h"
#import "log2.h"
#import "fft.h"
#include <math.h>


/*  LOCAL DEFINES  ***********************************************************/
#define SIDE_MARGIN       15.0
#define SIDE_OFFSET       5.0
#define TOP_MARGIN        10.0
#define VERTICAL_LINES    4

#define LOG_SCALE_RANGE   70.0

#define FONT @"Helvetica"
#define LINEAR_FONT_SIZE  8.0
#define LOG_FONT_SIZE     7.5
#define NUMBER_MARGIN     3.0

#define BAR_WIDTH         2.0
#define BAR_MARGIN        2.0

#define HARMONICS_GP      0
#define HARMONICS_SINE    1

#define TABLESIZE_MIN     64



@implementation HarmonicsView

- initWithFrame:(NSRect)frameRect
{
    /*  DO REGULAR INITIALIZATION  */
    [super initWithFrame:frameRect];

    /*  CALCULATE ACTIVE AREA  */
    activeArea = NSMakeRect(NSMinX([self bounds]), NSMinY([self bounds]), NSWidth([self bounds]), NSHeight([self bounds]));
    activeArea = NSInsetRect(activeArea , SIDE_MARGIN , TOP_MARGIN);
    activeArea = NSOffsetRect(activeArea , SIDE_OFFSET , 0.0);

    /*  CALCULATE THE NUMBER OF HARMONICS  */
    numberHarmonics = (int)(NSWidth(activeArea) / (BAR_WIDTH + BAR_MARGIN));

    /*  CALCULATE TABLE SIZE  */
    tableSize = pow(2.0, (int)(log2((double)numberHarmonics)) + 1) * 2;
    tableSize = tableSize < TABLESIZE_MIN? TABLESIZE_MIN: tableSize;

    /*  ALLOCATE MEMORY FOR THE WAVETABLE  */
    wavetable = (float *)calloc(tableSize, sizeof(float));

    /*  ALLOCATE BACKGROUND NXIMAGES  */
    linearGrid = [[NSImage alloc] initWithSize:(frameRect.size)];
    logGrid = [[NSImage alloc] initWithSize:(frameRect.size)];

    /*  DRAW BACKGROUND GRIDS */
    [self drawLinearGrid];
    [self drawLogGrid];

    /*  ALLOCATE A FOREGROUND NXIMAGES  */
    sineHarmonics = [[NSImage alloc] initWithSize:(frameRect.size)];
    glottalPulseHarmonics = [[NSImage alloc] initWithSize:(frameRect.size)];

    /*  DRAW SINE HARMONICS  */
    [self drawSineHarmonics];

    return self;
}



- (void)dealloc
{
    /*  FREE WAVETABLE MEMORY  */
    cfree(wavetable);

    /*  FREE BACKGROUND NXIMAGES  */
    [linearGrid release];
    [logGrid release];
    
    /*  FREE FOREGROUND NXIMAGES  */
    [sineHarmonics release];
    [glottalPulseHarmonics release];
    
    /*  DO REGULAR FREE  */
    { [super dealloc]; return; };
}



- (void)drawLinearGrid
{
    float verticalIncrement;
    int i;
    NSFont *fontObject1;

    /*  SET UP FONT  */
    fontObject1 = [NSFont fontWithName: FONT size: LINEAR_FONT_SIZE];

    /*  LOCK FOCUS ON BACKGROUND NXIMAGE  */
    [linearGrid lockFocus];

    /*  DRAW WHITE BACKGROUND WITH BORDER  */
    NSDrawWhiteBezel([self bounds] , [self bounds]);

    /*  DRAW LIGHT GRAY ENCLOSURE  */
    PSrectangle(NSMinX(activeArea), NSMinY(activeArea),
		NSWidth(activeArea), NSHeight(activeArea),
		1.0, NSLightGray);

    /*  DRAW HORIZONTAL LINES  */
    verticalIncrement = NSHeight(activeArea) / (float)VERTICAL_LINES;
    for (i = 1; i < VERTICAL_LINES; i++) {
	PSmoveto(NSMinX(activeArea),
		 NSMinY(activeArea) + ((float)i * verticalIncrement));
	PSrlineto(NSWidth(activeArea), 0.0);
    }
    PSstroke();

    /*  NUMBER HORIZONTAL LINES  */
    [fontObject1 set];
    PSsetgray(NSBlack);
    for (i = 0; i <= VERTICAL_LINES; i++) {
	char number[12];
	int scaledNumber;
	float value = (float)i/(float)VERTICAL_LINES;
	float px, py;

	/*  FORMAT THE NUMBER  */
	scaledNumber = (int)(100.0 * value);
	if (!(scaledNumber % 100))
	    sprintf(number, "%-d", (int)value);
	else if (!(scaledNumber % 50))
	    sprintf(number, ".%-d", scaledNumber/10);
	else
	    sprintf(number, ".%-d", scaledNumber);

	/*  DETERMINE STRING WIDTH  */
	PSstringwidth(number, &px, &py);

	PSmoveto(NSMinX(activeArea) - px - NUMBER_MARGIN,
		 NSMinY(activeArea) + ((float)i * verticalIncrement)
		 - LINEAR_FONT_SIZE / 2.0 + 1.0);

	/*  DRAW THE NUMBER ON THE GRID  */
	PSshow(number);
    }

    /*  UNLOCK FOCUS ON BACKGROUND NXIMAGE  */
    [linearGrid unlockFocus]; 
}



- (void)drawLogGrid
{
    float verticalIncrement;
    int i, verticalLines;
    NSFont *fontObject1;

    /*  SET UP FONT  */
    fontObject1 = [NSFont fontWithName: FONT size: LOG_FONT_SIZE];

    /*  LOCK FOCUS ON BACKGROUND NXIMAGE  */
    [logGrid lockFocus];

    /*  DRAW WHITE BACKGROUND WITH BORDER  */
    NSDrawWhiteBezel([self bounds] , [self bounds]);

    /*  DRAW LIGHT GRAY ENCLOSURE  */
    PSrectangle(NSMinX(activeArea), NSMinY(activeArea),
		NSWidth(activeArea), NSHeight(activeArea),
		1.0, NSLightGray);

    /*  DRAW HORIZONTAL LINES  */
    verticalLines = (int)(LOG_SCALE_RANGE / 10.0);
    verticalIncrement = NSHeight(activeArea) / (float)verticalLines;
    for (i = 1; i < verticalLines; i++) {
	PSmoveto(NSMinX(activeArea),
		 NSMinY(activeArea) + ((float)i * verticalIncrement));
	PSrlineto(NSWidth(activeArea), 0.0);
    }
    PSstroke();

    /*  NUMBER HORIZONTAL LINES  */
    [fontObject1 set];
    PSsetgray(NSBlack);
    for (i = 0; i <= verticalLines; i++) {
	char number[12];
	float px, py;
	int numberValue = -(i * 10);

	/*  FORMAT THE NUMBER  */
	sprintf(number, "%-d", numberValue);

	/*  DETERMINE STRING WIDTH  */
	PSstringwidth(number, &px, &py);

	PSmoveto(NSMinX(activeArea) - px - NUMBER_MARGIN,
		 NSMaxY(activeArea) - ((float)i * verticalIncrement)
		 - LOG_FONT_SIZE / 2.0 + 1.0);

	/*  DRAW THE NUMBER ON THE GRID  */
	PSshow(number);
    }

    /*  UNLOCK FOCUS ON BACKGROUND NXIMAGE  */
    [logGrid unlockFocus]; 
}



- (void)drawSineHarmonics
{
    /*  LOCK FOCUS ON NXIMAGE  */
    [sineHarmonics lockFocus];

    /*  CLEAR THE NXIMAGE  */
    [sineHarmonics compositeToPoint:[self bounds].origin operation:NSCompositeClear];

    /*  DRAW THE 1ST HARMONIC  */
    PSsetgray(NSBlack);
    PSrectfill(NSMinX(activeArea) + BAR_MARGIN + 1.0, NSMinY(activeArea),
	       BAR_WIDTH, NSHeight(activeArea));

    /*  UNLOCK FOCUS ON NXIMAGE  */
    [sineHarmonics unlockFocus]; 
}



- (void)drawSineScale:(BOOL)scale
{
    /*  RECORD THE SCALE  */
    logScale = scale;

    /*  USE SINE HARMONICS NXIMAGE  */
    harmonics = HARMONICS_SINE;

    /*  DISPLAY THE COMBINED IMAGES  */
    [self display]; 
}



- (void)drawGlottalPulseAmplitude:(float)amplitude RiseTime:(float)riseTime FallTimeMin:(float)fallTimeMin FallTimeMax:(float)fallTimeMax Scale:(BOOL)scale
{
    int i, firstDivision, secondDivision;
    double fall, delta;

    /*  RECORD THE SCALE  */
    logScale = scale;

    /*  USE GLOTTAL PULSE HARMONICS NXIMAGE  */
    harmonics = HARMONICS_GP;

    /*  FILL THE WAVETABLE  */
    /*  CALCULATE TABLE DIVISIONS  */
    firstDivision = (int)rint((double)(riseTime/100.0 * (double)tableSize));
    delta = (fallTimeMax - fallTimeMin) * amplitude;
    fall = (riseTime + fallTimeMax - delta)/100.0 * (double)tableSize;
    secondDivision = (int)rint((double)fall);

    /*  CALCULATE RISE PORTION  */
    for (i = 0; i < firstDivision; i++) {
	float x = (float)i / (float)firstDivision;
	float x2 = x * x;
	float x3 = x * x2;
	wavetable[i] = (3.0 * x2) - (2.0 * x3);
    }

    /*  CALCULATE FALL PORTION  */
    for (i = firstDivision; i < secondDivision; i++) {
	float x = (float)(i - firstDivision) /
	    (float)(secondDivision - firstDivision);
	wavetable[i] = 1.0 - (x * x);
    }

    /*  FILL BALANCE WITH ZEROS  */
    for (i = secondDivision; i < tableSize; i++)
	wavetable[i] = 0.0;

    /*  DO FFT ON WAVETABLE  */
    realfft(wavetable, tableSize);

    /*  IF LOG DISPLAY, SCALE THE HARMONICS  */
    if (logScale) {
	for (i = 0; i < numberHarmonics; i++)
	    wavetable[i] = ((log10(wavetable[i]) * 20.0) + LOG_SCALE_RANGE) /
		            LOG_SCALE_RANGE;
    }

    /*  LOCK FOCUS ON THE GLOTTAL PULSE NXIMAGE  */
    [glottalPulseHarmonics lockFocus];

    /*  CLEAR THE NXIMAGE  */
    [glottalPulseHarmonics compositeToPoint:[self bounds].origin operation:NSCompositeClear];

    /*  DRAW BAR GRAPH FOR EACH HARMONIC DISPLAYED  */
    {
	float xStart = NSMinX(activeArea) + BAR_MARGIN + 1.0;
	float xIncrement = BAR_MARGIN + BAR_WIDTH;
	for (i = 0; i < numberHarmonics; i++) {
	    PSrectfill(xStart + i * xIncrement,
		       NSMinY(activeArea),
		       BAR_WIDTH,
		       NSHeight(activeArea) * wavetable[i]);
	}
    }

    /*  UNLOCK FOCUS ON THE GLOTTAL PULSE  NXIMAGE  */
    [glottalPulseHarmonics unlockFocus];

    /*  DISPLAY THE COMBINED IMAGES  */
    [self display]; 
}



- (void)drawRect:(NSRect)rects
{
    /*  COMPOSITE APPROPRIATE BACKGROUND IMAGE  */
    if (logScale)
	[logGrid compositeToPoint:(rects.origin) operation:NSCompositeSourceOver];
    else
	[linearGrid compositeToPoint:(rects.origin) operation:NSCompositeSourceOver];


    /*  COMPOSITE THE FOREGROUND IMAGE OVER THE BACKGROUND  */
    if (harmonics == HARMONICS_GP)
	[glottalPulseHarmonics compositeToPoint:(rects.origin) operation:NSCompositeSourceOver];
    else if (harmonics == HARMONICS_SINE)
	[sineHarmonics compositeToPoint:(rects.origin) operation:NSCompositeSourceOver];
}

@end
