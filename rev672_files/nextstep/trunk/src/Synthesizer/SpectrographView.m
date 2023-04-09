/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/SpectrographView.m,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

# Revision 1.1.1.1  1994/05/20  00:22:06  len
# Initial archive of TRM interactive Synthesizer.
#

******************************************************************************/

/*  HEADER FILES  ************************************************************/
#import "SpectrographView.h"
#import "AnalysisData.h"
#import "PSwraps.h"
#import "dsp_control.h"
#include <math.h>


/*  LOCAL DEFINES  ***********************************************************/
#define SIDE_MARGIN     24.0
#define TOP_MARGIN      10.0
#define TIC_LENGTH      4.0
#define NUMBER_MARGIN   3.0

#define FREQ_DIV        10
#define NYQUIST         (OUTPUT_SRATE/2.0)

#define FONT @"Helvetica"
#define FONT_SIZE       8.0

#define LINEAR          0
#define LOG             1


/*  GLOBAL FUNCTIONS (LOCAL TO THIS FILE)  ***********************************/
static float normalizedValue(float value, float lowerThreshold, float range);
static float gray(float value, BOOL quantized);
static float dbValue(float value);



@implementation SpectrographView

- initWithFrame:(NSRect)frameRect
{
    NSPoint hotSpot;

    /*  DO REGULAR INITIALIZATION  */
    self = [super initWithFrame:frameRect];

    /*  ALLOCATE & INITIALIZE NXIMAGES  */
    background = [[NSImage alloc] initWithSize:([self bounds].size)];
    grid = [[NSImage alloc] initWithSize:([self bounds].size)];
    spectrograph = [[NSImage alloc] initWithSize:([self bounds].size)];

    /*  SET CROSS HAIR CURSOR FOR VIEW  */
    crosshairCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosshairCursor.tiff"]];
    hotSpot.x = 8.0;  hotSpot.y = 8.0;
    [crosshairCursor setHotSpot:hotSpot];

    /*  CALCULATE ACTIVE AREA  */
    [self calculateActiveArea];

    /*  DRAW BACKGROUNDS  */
    [self drawBackground];
    [self drawGrid];
    

    return self;
}



- (void)dealloc
{
    /*  FREE NXIMAGES  */
    [background release];
    [grid release];
    [spectrograph release];

    /*  FREE THE NXCURSOR  */
    [crosshairCursor release];

    /*  DO REGULAR FREE  */
    { [super dealloc]; return; };
}



- (void)resetCursorRects
{
    /*  USE CROSSHAIR ONLY WHEN INSIDE ACTIVE AREA  */
    [self addCursorRect:activeArea cursor:crosshairCursor];

    /*  SET UP MOUSE TRACKING  */
    [self setMouseTracking];
}



- (void)setFrameSize:(NSSize)_newSize
{
    /*  DO NORMAL RESIZING FIRST  */
    [super setFrameSize:_newSize];

    /*  RECALCULATE ACTIVE AREA  */
    [self calculateActiveArea];

    /*  RESET THE SIZE OF THE BACKGROUND, AND REDRAW IT  */
    [background setSize:([self bounds].size)];
    [self drawBackground];

    /*  RESET THE SIZE OF THE GRID, AND REDRAW IT  */
    [grid setSize:([self bounds].size)];
    [self drawGrid];

    /*  RESET THE SIZE OF THE SPECTROGRAPH NXIMAGE, AND REDRAW IT  */
    [spectrograph setSize:([self bounds].size)];
    [self drawSpectrograph];
}



- (void)setMouseTracking
{
    NSRect tempFrame;

    /*  DISCARD OLD TRACKING RECTANGLE IF NECESSARY  */
    if (trackingTag != 0)
	[self removeTrackingRect: trackingTag];

    /*  SET RECTANGLE TO TRACK & CONVERT TO WINDOW'S COORDINATES  */
    tempFrame = NSMakeRect(NSMinX(activeArea), NSMinY(activeArea), NSWidth(activeArea), NSHeight(activeArea));
    [self convertRect:tempFrame toView:nil];

    /*  SET THE TRACKING RECTANGLE  */
    trackingTag = [self addTrackingRect:tempFrame owner:self 
			userData: NULL assumeInside:NO]; 
}



- (void)mouseEntered:(NSEvent *)e 
{
    NSEvent *eventPtr, *nextEventPtr;
    NSPoint mLoc;

    /*  CHANGE TO A CROSSHAIR CURSOR, IF THE WINDOW IS NOT KEY  */
    if (![[self window] isKeyWindow])
	[crosshairCursor push];

    /*  GET IMMEDIATE MOUSE LOCATION  */
    mLoc = [[self window] mouseLocationOutsideOfEventStream];

    /*  TRANSLATE POSITION INTO THAT OF ACTIVE AREA  */
    [self convertPoint:mLoc];

    /*  DISPLAY EQUIVALENT FREQUENCY WITHIN ACTIVE AREA  */
    [self trackMouse:mLoc];
    
    /*  SET UP MASK SO THAT MOUSE MOVED EVENTS ARE ALSO RECEIVED  */
    [[self window] setAcceptsMouseMovedEvents: YES];

    /*  MODAL LOOP  */
    for (; ;) {
	/*  GRAB ALL EVENTS;  SEND ALL BUT MOUSE MOVED AND EXITED BACK TO NXApp  */
	eventPtr = [[self window] nextEventMatchingMask:NSAnyEventMask];
        if (([eventPtr type] != NSMouseMoved) && ([eventPtr type] != NSMouseExited)){
	    /*  POP CROSSHAIR CURSOR, SINCE IT IS IMMEDIATELY PUSHED AGAIN  */
	    if (![[self window] isKeyWindow])
		[crosshairCursor pop];
	    /*  SEND EVENT BACK TO THE APPLICATION OBJECT  */
	    [NSApp sendEvent:eventPtr];
	}

	/*  IF EVENT IS A MOUSEEXITED, EXIT  */
	if ([eventPtr type] == NSMouseExited)
	    break;

	/*  IF FOLLOWING EVENT IS A MOUSE EXITED, THEN EXIT  */
	nextEventPtr = [NSApp nextEventMatchingMask: 
				(NSMouseMovedMask | NSMouseExitedMask)
			      untilDate: [NSDate distantFuture]
			      inMode: NSEventTrackingRunLoopMode
			      dequeue: NO];
        if ((nextEventPtr != NULL) && ([nextEventPtr type] == NSMouseExited))
	    break;

	/*  IF MOUSE MOVED EVENT, AND STILL KEY WINDOW, CALCULATE MOUSE POSITION  */
	if ([eventPtr type] == NSMouseMoved) {
	    mLoc.x = [eventPtr locationInWindow].x;
	    mLoc.y = [eventPtr locationInWindow].y;
	    
	    /*  TRANSLATE POSITION INTO THAT OF ACTIVE AREA  */
	    [self convertPoint:mLoc];

	    /*  DISPLAY EQUIVALENT FREQUENCY WITHIN ACTIVE AREA  */
	    [self trackMouse:mLoc];
	}
    }

    /*  IF THE WINDOW ISN'T KEY, RESTORE THE ORIGINAL CURSOR  */
    if (![[self window] isKeyWindow])
	[crosshairCursor pop];

    /*  STOP PROCESSING MOUSE MOVED EVENTS  */
    [[self window] setAcceptsMouseMovedEvents: NO];

    /*  STOP DISPLAY OF FREQUENCY  */
    [self stopTrackingMouse];
}



- (void)trackMouse:(NSPoint)mLoc
{
    /*  DISPLAY FREQUENCY IN FREQUENCY DISPLAY  */
    [frequencyDisplay setIntValue:(int)rint(((mLoc.y)/NSHeight(activeArea)) * NYQUIST)]; 
}



- (void)stopTrackingMouse
{
    /*  BLANK DISPLAY  */
    [frequencyDisplay setStringValue:@""]; 
}



- (void)convertPoint:(NSPoint)location
{
    /*  FIRST TRANSLATE POSITION FROM WINDOW TO THAT OF VIEW  */
    location = [self convertPoint:location fromView:nil];

    /*  THEN TRANSLATE TO POSITION WITHIN ACTIVE AREA  */
    location.x -= NSMinX(activeArea);
    location.y -= NSMinY(activeArea); 
}



- (void)calculateActiveArea
{
    /*  CALCULATE ACTIVE AREA  */
    activeArea = NSMakeRect(NSMinX([self bounds]), NSMinY([self bounds]), NSWidth([self bounds]), NSHeight([self bounds]));
    activeArea = NSInsetRect(activeArea , SIDE_MARGIN , TOP_MARGIN);
    activeArea = NSOffsetRect(activeArea , (0.5 * SIDE_MARGIN) , 0.0); 
}



- (void)setGrid:(BOOL)flag
{
    /*  RECORD IF GRID DISPLAY ON  */
    gridDisplay = flag;

    /*  REDISPLAY  */
    [self display]; 
}



- (void)drawBackground
{
    int i;
    float deltaY, leftMargin, bottomMargin, px, py;
    char number[12];
    NSFont *fontObject1;

    /*  LOCK FOCUS ON BACKGROUND NXIMAGE  */
    [background lockFocus];

    /*  SET UP FONT  */
    fontObject1 = [NSFont fontWithName: FONT size: FONT_SIZE];

    /*  DRAW WHITE BACKGROUND WITH BORDER  */
    NSDrawWhiteBezel([self bounds] , [self bounds]);

    /*  DRAW LEFT HAND TIC MARKS  */
    deltaY = NSHeight(activeArea) / (float)FREQ_DIV;
    for (i = 0; i < FREQ_DIV; i++) {
	PSmoveto(NSMinX(activeArea), NSMinY(activeArea) + ((float)i * deltaY));
	PSrlineto(-TIC_LENGTH,0.0);
    }
    /*  DO TOP TIC SEPARATELY, TO AVOID OCCASIONAL ROUNDING PROBLEM  */
    PSmoveto(NSMinX(activeArea), NSMaxY(activeArea));
    PSrlineto(-TIC_LENGTH,0.0);
    PSsetgray(NSBlack);
    PSstroke();

    /*  NUMBER TICS  */
    [fontObject1 set];
    leftMargin = NSMinX(activeArea) - NUMBER_MARGIN - TIC_LENGTH;
    bottomMargin = NSMinY(activeArea) - (FONT_SIZE / 2.0) + 1.0;

    /*  NUMBER BOTTOM TIC  */
    sprintf(number, "%-d", 0);
    PSstringwidth(number, &px, &py);
    PSmoveto(leftMargin - px, bottomMargin);
    PSshow(number);

    /*  NUMBER TOP TIC  */
    sprintf(number, "%-d", (int)NYQUIST);
    PSstringwidth(number, &px, &py);
    PSmoveto(leftMargin - px, bottomMargin + NSHeight(activeArea));
    PSshow(number);

    /*  NUMBER OTHER TICS, USING QUANTIZATION TO NEAREST PIXEL  */
    for (i = 1; i < FREQ_DIV; i++) {
	int quantizedY, quantizedNumber;

	/*  FIND QUANTIZED NUMBER  */
	quantizedY = (int)((float)i * deltaY) + 1;
	quantizedNumber =
	    (int)rint(((float)quantizedY * NYQUIST)/NSHeight(activeArea));

	/*  FORMAT THE NUMBER  */
	sprintf(number, "%-d", quantizedNumber);

	/*  DETERMINE STRING WIDTH  */
	PSstringwidth(number, &px, &py);
	PSmoveto(leftMargin - px, bottomMargin + ((float)i * deltaY));

	/*  DRAW THE NUMBER ON THE GRID  */
	PSshow(number);
    }

    /*  UNLOCK FOCUS ON BACKGROUND NXIMAGE  */
    [background unlockFocus]; 
}



- (void)drawGrid
{
    float deltaY;
    int i;

    /*  LOCK FOCUS ON GRID NXIMAGE  */
    [grid lockFocus];

    /*  CLEAR THE NXIMAGE  */
    [grid compositeToPoint:[self bounds].origin operation:NSCompositeClear];

    /*  DRAW BLACK ENCLOSURE  */
    PSrectangle(NSMinX(activeArea), NSMinY(activeArea),
		NSWidth(activeArea), NSHeight(activeArea),
		1.0, NSBlack);

    /*  DRAW HORIZONTAL LINES  */
    deltaY = NSHeight(activeArea) / (float)FREQ_DIV;
    for (i = 1; i < FREQ_DIV; i++) {
	PSmoveto(NSMinX(activeArea), NSMinY(activeArea) + ((float)i * deltaY));
	PSrlineto(NSWidth(activeArea),0.0);
    }
    PSstroke();

    /*  UNLOCK FOCUS ON GRID NXIMAGE  */
    [grid unlockFocus]; 
}



- (void)displayAnalysis:analysisDataObj grayLevel:(int)grayLevelType magnitudeScale:(int)scaleType linearUpperThreshold:(float)linearUT linearLowerThreshold:(float)linearLT logUpperThreshold:(float)logUT logLowerThreshold:(float)logLT
{
    /*  RECORD INPUT VALUES  */
    analysisDataObject = analysisDataObj;
    grayLevel = grayLevelType;
    magnitudeScale = scaleType;
    linearUpperThreshold = linearUT;
    linearLowerThreshold = linearLT;
    logUpperThreshold = logUT;
    logLowerThreshold = logLT;

    /*  CALCULATE RANGES TO DRAW IN  */
    linearRange = linearUpperThreshold - linearLowerThreshold;
    logRange = logUpperThreshold - logLowerThreshold;

    /*  DRAW THE SPECTROGRAPH  */
    [self drawSpectrograph];

    /*  DISPLAY THE SPECTROGRAPH  */
    [self display]; 
}



- (void)drawSpectrograph
{
    int i, spectrumSize;
    float verticalIncrement, yOrigin;
    const float *analysisData;


    /*  LOCK FOCUS ON SPECTROGRAPH NXIMAGE  */
    [spectrograph lockFocus];

    /*  CLEAR THE NXIMAGE  */
    [spectrograph compositeToPoint:[self bounds].origin operation:NSCompositeClear];

    /*  RETURN IMMEDIATELY IF THERE NO ANALYSIS TO DRAW  */
    if (![analysisDataObject haveAnalyzedData]) {
	[spectrograph unlockFocus];
	return;
    }

    /*  RETURN IMMEDIATE IF THE RANGE TO DRAW IN IS 0  */
    if ((magnitudeScale == LINEAR) && (linearRange <= 0.0)) {
	[spectrograph unlockFocus];
	return;
    }
    else if ((magnitudeScale == LOG) && (logRange <= 0)) {
	[spectrograph unlockFocus];
	return;
    }

    /*  RECORD THE SPECTRUM SIZE  */
    spectrumSize = [analysisDataObject spectrumSize];

    /*  CALCULATE THE VERTICAL INCREMENT  */
    verticalIncrement = NSHeight(activeArea) / (float)spectrumSize;

    /*  CALCULATE OFFSET Y ORIGIN  */
    yOrigin = NSMinY(activeArea) + verticalIncrement / 2.0;
    
    /*  GET THE ANALYSIS DATA BUFFER  */
    analysisData = [analysisDataObject analysisData];

    /*  DRAWING LOOP  */
    for (i = 0; i < (spectrumSize - 1); i++) {
	/*  SET THE GRAY LEVEL FOR THE ANALYSIS DATA POINT  */
	if (magnitudeScale == LINEAR) {
	    PSsetgray(gray(normalizedValue(analysisData[i],
					   linearLowerThreshold,
					   linearRange), grayLevel));
	}
	else {
	    PSsetgray(gray(normalizedValue(dbValue(analysisData[i]),
					   logLowerThreshold,
					   logRange), grayLevel));
	}

	/*  DO THE ACTUAL DRAWING  */
	PSrectfill(NSMinX(activeArea), yOrigin + ((float)i*verticalIncrement),
		   NSWidth(activeArea), verticalIncrement);
    }

    /*  DRAW NYQUIST COMPONENT WITH HALF BIN SIZE  */
    /*  SET THE GRAY LEVEL FOR THE ANALYSIS DATA POINT  */
    if (magnitudeScale == LINEAR) {
	PSsetgray(gray(normalizedValue(analysisData[i],
				       linearLowerThreshold,
				       linearRange), grayLevel));
    }
    else {
	PSsetgray(gray(normalizedValue(dbValue(analysisData[i]),
				       logLowerThreshold,
				       logRange), grayLevel));
    }
    
    /*  DO THE ACTUAL DRAWING  */
    PSrectfill(NSMinX(activeArea), yOrigin + ((float)i*verticalIncrement),
	       NSWidth(activeArea), verticalIncrement/2.0);
    

    /*  UNLOCK FOCUS ON SPECTROGRAPH NXIMAGE  */
    [spectrograph unlockFocus]; 
}



- (void)drawRect:(NSRect)rects
{
    /*  COMPOSITE BACKGROUND  */
    [background compositeToPoint:(rects.origin) operation:NSCompositeSourceOver];

    /*  COMPOSITE SPECTROGRAPH  */
    [spectrograph compositeToPoint:(rects.origin) operation:NSCompositeSourceOver];

    /*  COMPOSITE GRID, IF ASKED FOR  */
    if (gridDisplay)
	[grid compositeToPoint:(rects.origin) operation:NSCompositeSourceOver];
}



/******************************************************************************
*
*	function:	normalizedValue
*
*	purpose:	Normalizes the input value to a value between 0 and 1,
*                       using the range and lowerThreshold arguments to scale
*			to scale properly.  Assumes a linear scale.
*
*       arguments:      value - value to be normalized
*                       lowerThreshold - value of bottom of range
*                       range - range over which to normalize
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

float normalizedValue(float value, float lowerThreshold, float range)
{
    /*  NORMALIZE THE INPUT VALUE  */
    float normalizedValue = (value - lowerThreshold) / range;

    /*  LIMIT OUT-OF-RANGE VALUES  */
    if (normalizedValue > 1.0) return(1.0);
    if (normalizedValue < 0.0) return(0.0);

    /*  RETURN NORMALIZED VALUE  */
    return(normalizedValue);
}



/******************************************************************************
*
*	function:	gray
*
*	purpose:	Returns the appropriate gray level for the input value,
*                       quantizing to nearest pure gray if asked for.
*			
*       arguments:      value - the input magnitude ranging from 0 to 1
*                       quantized - set to 1 if quantized gray desired,
*                                   0 for continuous gray.
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

float gray(float value, BOOL quantized)
{
    if (quantized) {
	float gray = NSWhite;
	if (value > 0.25) {
	    gray = NSLightGray;
	    if (value > 0.5) {
		gray = NSDarkGray;
		if (value > 0.75) {
		    gray = NSBlack;
		}
	    }
	}
	return(gray);
    }
    else {
	return(1.0 - value);
    }
}



/******************************************************************************
*
*	function:	dbValue
*
*	purpose:	Converts a linear value between 0 and 1 to to a dB
*                       value, with 0 dB equal to unity gain, and lower
*			amplitudes equal to negative dB values.
*
*       arguments:      value - linear input value, with 1.0 equal to unity
*                               gain.
*	internal
*	functions:	none
*
*	library
*	functions:	log10
*
******************************************************************************/

float dbValue(float value)
{
    return(20.0 * log10(value));
}

@end
