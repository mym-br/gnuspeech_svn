/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/SpectrumView.m,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

# Revision 1.1.1.1  1994/05/20  00:22:06  len
# Initial archive of TRM interactive Synthesizer.
#

******************************************************************************/

/*  HEADER FILES  ************************************************************/
#import "SpectrumView.h"
#import "AnalysisData.h"
#import "PSwraps.h"
#import "dsp_control.h"
#include <math.h>


/*  LOCAL DEFINES  ***********************************************************/
#define SIDE_MARGIN        20.0
#define TOP_MARGIN         10.0
#define TIC_LENGTH         4.0
#define NUMBER_MARGIN      3.0

#define FREQ_DIV           10
#define LINEAR_AMPL_DIV    10
#define LOG_AMPL_DIV       9
#define LOG_SPACING        10.0
#define LOG_TOTAL_SCALE    ((float)LOG_AMPL_DIV * LOG_SPACING)

#define NYQUIST            (OUTPUT_SRATE/2.0)
#define SPECTRUM_SIZE_MAX  (DMA_OUT_SIZE/2)
#define DATA_POINTS_MAX    (SPECTRUM_SIZE_MAX + 1)

#define FONT @"Helvetica"
#define FONT_SIZE       8.0

#define LINEAR          0
#define LOG             1


/*  GLOBAL FUNCTIONS (LOCAL TO THIS FILE)  ***********************************/
static float dbValue(float value);



@implementation SpectrumView

- initWithFrame:(NSRect)frameRect
{
    NSPoint hotSpot;

    /*  DO REGULAR INITIALIZATION  */
    self = [super initWithFrame:frameRect];

    /*  ALLOCATE & INITIALIZE NXIMAGES  */
    linearBackground = [[NSImage alloc] initWithSize:([self bounds].size)];
    logBackground = [[NSImage alloc] initWithSize:([self bounds].size)];
    linearGrid = [[NSImage alloc] initWithSize:([self bounds].size)];
    logGrid = [[NSImage alloc] initWithSize:([self bounds].size)];
    spectrum = [[NSImage alloc] initWithSize:([self bounds].size)];

    /*  SET CROSS HAIR CURSOR FOR VIEW  */
    crosshairCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosshairCursor.tiff"]];
    hotSpot.x = 8.0;  hotSpot.y = 8.0;
    [crosshairCursor setHotSpot:hotSpot];

    /*  INITIALIZE THE USER PATH  */
    [self initializeUserPath];

    /*  CALCULATE ACTIVE AREA  */
    [self calculateActiveArea];

    /*  RESET THE USER PATH  */
    [self resetUserPath];

    /*  DRAW BACKGROUNDS  */
    [self drawLinearBackground];
    [self drawLogBackground];
    [self drawLinearGrid];
    [self drawLogGrid];
    

    return self;
}



- (void)dealloc
{
    /*  FREE NXIMAGES  */
    [linearBackground release];
    [logBackground release];
    [linearGrid release];
    [logGrid release];
    [spectrum release];

    /*  FREE USER PATH MEMORY  */
    [self freeUserPath];

    /*  FREE THE NXCURSOR  */
    [crosshairCursor release];

    /*  DO REGULAR FREE  */
    { [super dealloc]; return; };
}



- initializeUserPath
{
    /*  ALLOCATE SPACE FOR THE USER PATH COORDINATES & OPERATORS  */
    coord = (float *)calloc((DATA_POINTS_MAX*2),sizeof(float));

    return self;
}



- (void)freeUserPath
{
    /*  FREE SPACE USED FOR USER PATH COORDINATES & OPERATORS  */
    cfree((char *)coord);
}



- (void)resetUserPath
{
    /*  SET THE BOUNDING BOX FOR THE USER PATH  */
    bbox[0] = NSMinX(activeArea);
    bbox[1] = NSMinY(activeArea);
    bbox[2] = NSMaxX(activeArea);
    bbox[3] = NSMaxY(activeArea);

    /*  INITIALIZE BEGINNING Y COORDINATE  */
    coord[1] = NSMinY(activeArea);

    /*  CALCULATE THE DB SCALE FACTOR  */
    dbScale = NSHeight(activeArea) / LOG_TOTAL_SCALE; 
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

    /*  RESET THE USER PATH  */
    [self resetUserPath];

    /*  RESET THE SIZE OF THE BACKGROUNDS, AND REDRAW THEM  */
    [linearBackground setSize:([self bounds].size)];
    [self drawLinearBackground];
    [logBackground setSize:([self bounds].size)];
    [self drawLogBackground];

    /*  RESET THE SIZE OF THE GRIDS, AND REDRAW THEM  */
    [linearGrid setSize:([self bounds].size)];
    [self drawLinearGrid];
    [logGrid setSize:([self bounds].size)];
    [self drawLogGrid];

    /*  RESET THE SIZE OF THE SPECTRUM NXIMAGE, AND REDRAW IT  */
    [spectrum setSize:([self bounds].size)];
    [self drawSpectrum];
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
    trackingTag = [self addTrackingRect:tempFrame owner:self userData: NULL assumeInside:NO]; 
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

    /*  DISPLAY FREQUENCY & MAGNITUDE WITHIN ACTIVE AREA  */
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

	    /*  DISPLAY FREQUENCY & MAGNITUDE WITHIN ACTIVE AREA  */
	    [self trackMouse:mLoc];
	}
    }

    /*  IF THE WINDOW ISN'T KEY, RESTORE THE ORIGINAL CURSOR  */
    if (![[self window] isKeyWindow])
	[crosshairCursor pop];

    /*  STOP PROCESSING MOUSE MOVED EVENTS  */
    [[self window] setAcceptsMouseMovedEvents: NO];

    /*  STOP DISPLAY OF FREQUENCY & MAGNITUDE  */
    [self stopTrackingMouse];
}



- (void)trackMouse:(NSPoint)mLoc
{
    /*  DISPLAY FREQUENCY IN FREQUENCY DISPLAY  */
    [frequencyDisplay setIntValue:(int)rint(((mLoc.x)/NSWidth(activeArea)) * NYQUIST)];

    /*  DISPLAY FREQUENCY, EITHER IN DB OR LINEAR SCALE  */
    if (magnitudeScale == LINEAR) {
	[magnitudeDisplay setFloatingPointFormat:NO left:1 right:2];
	[magnitudeDisplay setFloatValue:(mLoc.y)/NSHeight(activeArea)];
    }
    else {
	float position = (mLoc.y)/NSHeight(activeArea);
	[magnitudeDisplay setFloatingPointFormat:NO left:3 right:0];
	[magnitudeDisplay setIntValue:(int)rint((1.0-position) * -LOG_TOTAL_SCALE)];
    } 
}



- (void)stopTrackingMouse
{
    /*  BLANK DISPLAYS  */
    [frequencyDisplay setStringValue:@""];
    [magnitudeDisplay setStringValue:@""]; 
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
    activeArea = NSInsetRect(activeArea , SIDE_MARGIN + (0.5 * TIC_LENGTH) , TOP_MARGIN + (0.5 * TOP_MARGIN) + (0.5 * TIC_LENGTH));
    activeArea = NSOffsetRect(activeArea , TIC_LENGTH , ((0.5 * TOP_MARGIN) + (0.5 * TIC_LENGTH))); 
}



- (void)setGrid:(BOOL)flag
{
    /*  RECORD IF GRID DISPLAY ON  */
    gridDisplay = flag;

    /*  REDISPLAY  */
    [self display]; 
}



- drawBottomScale
{
    float deltaX, leftMargin, bottomMargin, px, py;
    int i, inc;
    char number[12];

    /*  DRAW BOTTOM TIC MARKS  */
    deltaX = NSWidth(activeArea) / (float)FREQ_DIV;
    for (i = 0; i <= FREQ_DIV; i++) {
	PSmoveto(NSMinX(activeArea) + ((float)i * deltaX), NSMinY(activeArea));
	PSrlineto(0.0,-TIC_LENGTH);
    }

    /*  DRAW LAST TIC MARK SEPARATELY, TO AVOID ROUNDING PROBLEMS  */
    PSmoveto(NSMaxX(activeArea), NSMinY(activeArea));
    PSrlineto(0.0,-TIC_LENGTH);
    PSsetgray(NSLightGray);
    PSstroke();

    /*  NUMBER BOTTOM TICS  */
    /*  DETERMINE IF WE HAVE ENOUGH ROOM TO NUMBER EVERY TIC  */
    PSstringwidth("11025", &px, &py);
    if (deltaX < (px * 1.2))
	inc = 2;
    else
	inc = 1;

    /*  CALCULATE MARGINS  */
    leftMargin = NSMinX(activeArea);
    bottomMargin = NSMinY(activeArea) - (1.5 * FONT_SIZE) - TIC_LENGTH;

    /*  NUMBER LEFTMOST TIC  */
    sprintf(number, "%-d", 0);
    PSstringwidth(number, &px, &py);
    PSmoveto((leftMargin - px/2.0), bottomMargin);
    PSsetgray(NSBlack);
    PSshow(number);

    /*  NUMBER RIGHTMOST TIC  */
    sprintf(number, "%-d", (int)NYQUIST);
    PSstringwidth(number, &px, &py);
    PSmoveto((NSMaxX(activeArea) - px/2.0), bottomMargin);
    PSshow(number);

    /*  NUMBER OTHER TICS, USING QUANTIZATION TO NEAREST PIXEL  */
    for (i = inc; i < FREQ_DIV; i += inc) {
	int quantizedX, quantizedNumber;

	/*  FIND QUANTIZED NUMBER  */
	quantizedX = (int)((float)i * deltaX);
	quantizedNumber =
	    (int)rint(((float)quantizedX * NYQUIST)/NSWidth(activeArea));

	/*  FORMAT THE NUMBER  */
	sprintf(number, "%-d", quantizedNumber);

	/*  DETERMINE STRING WIDTH  */
	PSstringwidth(number, &px, &py);
	PSmoveto(leftMargin - (px/2.0) + ((float)i * deltaX), bottomMargin);

	/*  DRAW THE NUMBER ON THE GRID  */
	PSshow(number);
    }

    return self;
}



- (void)drawLinearBackground
{
    int i;
    NSFont *fontObject1;
    float deltaY, leftMargin, bottomMargin, px, py;
    char number[12];

    /*  LOCK FOCUS ON LINEAR BACKGROUND NXIMAGE  */
    [linearBackground lockFocus];

    /*  SET UP FONT  */
    fontObject1 = [NSFont fontWithName: FONT size: FONT_SIZE];

    /*  DRAW WHITE BACKGROUND WITH BORDER  */
    NSDrawWhiteBezel([self bounds] , [self bounds]);

    /*  DRAW ENCLOSING BOX  */
    PSrectangle(NSMinX(activeArea), NSMinY(activeArea), NSWidth(activeArea),
		NSHeight(activeArea), 1.0, NSLightGray);

    /*  DRAW LEFT HAND TIC MARKS  */
    deltaY = NSHeight(activeArea) / (float)LINEAR_AMPL_DIV;
    for (i = 0; i <= LINEAR_AMPL_DIV; i++) {
	PSmoveto(NSMinX(activeArea), rint(NSMinY(activeArea) + ((float)i * deltaY)));
	PSrlineto(-TIC_LENGTH,0.0);
    }
    /*  DRAW TOP TIC MARK SEPARATELY, TO AVOID ROUNDING PROBLEMS  */
    PSmoveto(NSMinX(activeArea), NSMaxY(activeArea));
    PSrlineto(-TIC_LENGTH,0.0);
    PSsetgray(NSLightGray);
    PSstroke();

    /*  NUMBER LEFTHAND TICS  */
    [fontObject1 set];
    PSsetgray(NSBlack);
    leftMargin = NSMinX(activeArea) - NUMBER_MARGIN - TIC_LENGTH;
    bottomMargin = NSMinY(activeArea) - (FONT_SIZE / 2.0) + 1.0;

    /*  NUMBER 0 TIC  */
    sprintf(number, "%-d", 0);
    PSstringwidth(number, &px, &py);
    PSmoveto(leftMargin - px, bottomMargin);
    PSshow(number);

    /*  NUMBER TOP TIC  */
    sprintf(number, "%-d", 1);
    PSstringwidth(number, &px, &py);
    PSmoveto(leftMargin - px, bottomMargin + NSHeight(activeArea));
    PSshow(number);

    /*  NUMBER OTHER TICS  */
    for (i = 1; i < LINEAR_AMPL_DIV; i++) {
	/*  FORMAT THE NUMBER  */
	sprintf(number, "%.1f", (float)i/(float)LINEAR_AMPL_DIV);

	/*  DETERMINE STRING WIDTH  */
	PSstringwidth(number, &px, &py);
	PSmoveto(leftMargin - px, rint(bottomMargin + ((float)i * deltaY)));

	/*  DRAW THE NUMBER ON THE GRID  */
	PSshow(number);
    }

    /*  DRAW BOTTOM SCALE AND TIC MARKS  */
    [self drawBottomScale];

    /*  UNLOCK FOCUS ON LINEAR BACKGROUND NXIMAGE  */
    [linearBackground unlockFocus]; 
}



- (void)drawLogBackground
{
    int i;
    NSFont *fontObject1;
    float deltaY, leftMargin, topMargin, px, py;
    char number[12];

    /*  LOCK FOCUS ON LOG BACKGROUND NXIMAGE  */
    [logBackground lockFocus];

    /*  SET UP FONT  */
    fontObject1 = [NSFont fontWithName: FONT size: FONT_SIZE];

    /*  DRAW WHITE BACKGROUND WITH BORDER  */
    NSDrawWhiteBezel([self bounds] , [self bounds]);

    /*  DRAW ENCLOSING BOX  */
    PSrectangle(NSMinX(activeArea), NSMinY(activeArea), NSWidth(activeArea),
		NSHeight(activeArea), 1.0, NSLightGray);

    /*  DRAW LEFT HAND TIC MARKS  */
    deltaY = NSHeight(activeArea) / (float)LOG_AMPL_DIV;
    for (i = 0; i <= LOG_AMPL_DIV; i++) {
	PSmoveto(NSMinX(activeArea), rint(NSMinY(activeArea) + ((float)i * deltaY)));
	PSrlineto(-TIC_LENGTH,0.0);
    }
    /*  DRAW TOP TIC MARK SEPARATELY, TO AVOID ROUNDING PROBLEMS  */
    PSmoveto(NSMinX(activeArea), NSMaxY(activeArea));
    PSrlineto(-TIC_LENGTH,0.0);
    PSsetgray(NSLightGray);
    PSstroke();

    /*  NUMBER LEFTHAND TICS  */
    [fontObject1 set];
    PSsetgray(NSBlack);
    leftMargin = NSMinX(activeArea) - NUMBER_MARGIN - TIC_LENGTH;
    topMargin = NSMaxY(activeArea) - (FONT_SIZE / 2.0) + 1.0;
    for (i = 0; i <= LOG_AMPL_DIV; i++) {
	/*  FORMAT THE NUMBER  */
	sprintf(number, "%-d", (i * (-10)));

	/*  DETERMINE STRING WIDTH  */
	PSstringwidth(number, &px, &py);
	PSmoveto(leftMargin - px, rint(topMargin - ((float)i * (deltaY))));

	/*  DRAW THE NUMBER ON THE GRID  */
	PSshow(number);
    }

    /*  DRAW BOTTOM SCALE AND TIC MARKS  */
    [self drawBottomScale];

    /*  UNLOCK FOCUS ON LOG BACKGROUND NXIMAGE  */
    [logBackground unlockFocus]; 
}



- drawGridInRect:(NSRect *)rect grayLevel:(float)grayLevel 
    magnitudeDivisions:(int)magnitudeDivisions
    frequencyDivisions:(int)frequencyDivisions
{
    float deltaY, deltaX;
    int i;

    /*  DRAW MAGNITUDE LINES  */
    deltaY = NSHeight(*rect) / (float)magnitudeDivisions;
    for (i = 1; i < magnitudeDivisions; i++) {
	PSmoveto(NSMinX(*rect), rint(NSMinY(*rect) + ((float)i * deltaY)));
	PSrlineto(NSWidth(*rect),0.0);
    }

    /*  DRAW VERTICAL LINES  */
    deltaX = NSWidth(*rect) / (float)frequencyDivisions;
    for (i = 1; i < frequencyDivisions; i++) {
	PSmoveto(NSMinX(*rect) + ((float)i * deltaX), NSMinY(*rect));
	PSrlineto(0.0, NSHeight(*rect));
    }

    /*  SET COLOR AND STROKE THE LINES  */
    PSsetgray(grayLevel);
    PSstroke();

    return self;
}



- (void)drawLinearGrid
{
    /*  LOCK FOCUS ON LINEARGRID NXIMAGE  */
    [linearGrid lockFocus];

    /*  CLEAR THE NXIMAGE  */
    [linearGrid compositeToPoint:[self bounds].origin operation:NSCompositeClear];

    /*  DRAW THE GRID  */
    [self drawGridInRect:&activeArea grayLevel:NSLightGray
	  magnitudeDivisions:LINEAR_AMPL_DIV
	  frequencyDivisions:FREQ_DIV];
    
    /*  UNLOCK FOCUS ON LINEARGRID NXIMAGE  */
    [linearGrid unlockFocus]; 
}



- (void)drawLogGrid
{
    /*  LOCK FOCUS ON LOG GRID NXIMAGE  */
    [logGrid lockFocus];

    /*  CLEAR THE NXIMAGE  */
    [logGrid compositeToPoint:[self bounds].origin operation:NSCompositeClear];

    /*  DRAW THE GRID  */
    [self drawGridInRect:&activeArea grayLevel:NSLightGray
	  magnitudeDivisions:LOG_AMPL_DIV
	  frequencyDivisions:FREQ_DIV];
    
    /*  UNLOCK FOCUS ON LOG GRID NXIMAGE  */
    [logGrid unlockFocus]; 
}



- (void)displayAnalysis:analysisDataObj magnitudeScale:(int)scaleType
{

    /*  RECORD INPUT VALUES  */
    analysisDataObject = analysisDataObj;
    magnitudeScale = scaleType;

    /*  DRAW THE SPECTRUM  */
    [self drawSpectrum];

    /*  DISPLAY THE SPECTRUM  */
    [self display]; 
}



- (void)drawSpectrum
{
    int i, j, spectrumSize, numberPoints;
    float binWidth;
    const float *analysisData;


    /*  LOCK FOCUS ON SPECTRUM NXIMAGE  */
    [spectrum lockFocus];

    /*  CLEAR THE NXIMAGE  */
    [spectrum compositeToPoint:[self bounds].origin operation:NSCompositeClear];

    /*  RETURN IMMEDIATELY IF THERE NO ANALYSIS TO DRAW  */
    if (![analysisDataObject haveAnalyzedData]) {
	[spectrum unlockFocus];
	return;
    }

    /*  RECORD THE SPECTRUM SIZE  */
    spectrumSize = [analysisDataObject spectrumSize];

    /*  CALCULATE NUMBER OF POINTS ON PATH  */
    numberPoints = spectrumSize + 1;

    /*  CALCULATE THE BIN GRAPHING WIDTH  */
    binWidth = NSWidth(activeArea) / (float)spectrumSize;

    /*  INITIALIZE X COORDINATES  */
    for (i = 0, j = 0; i < numberPoints; i++, j += 2)
	coord[j] = NSMinX(activeArea) + ((float)i * binWidth);

    /*  GET THE ANALYSIS DATA BUFFER  */
    analysisData = [analysisDataObject analysisData];


    /*  DRAWING LOOP  */
    if (magnitudeScale == LINEAR) {
	for (i = 0, j = 3; i < spectrumSize; i++, j += 2) {
	    coord[j] = NSMinY(activeArea) +
		(analysisData[i] * NSHeight(activeArea));
	}
    }
    else {
	for (i = 0, j = 3; i < spectrumSize; i++, j += 2) {
	    float dbVal = dbValue(analysisData[i]);
	    if (dbVal < -LOG_TOTAL_SCALE) dbVal = -LOG_TOTAL_SCALE;
		
	    coord[j] = NSMaxY(activeArea) + (dbVal * dbScale);
	}
    }

    /*  TRACE USER PATH ON SPECTRUM NXIMAGE  */
    PSsetgray(NSBlack);
    PSDoUserPath(coord, numberPoints, 1);

    /*  UNLOCK FOCUS ON SPECTRUM NXIMAGE  */
    [spectrum unlockFocus]; 
}



- (void)drawRect:(NSRect)rects
{
    /*  COMPOSITE APPROPRIATE BACKGROUND  */
    if (magnitudeScale == LINEAR)
	[linearBackground compositeToPoint:(rects.origin) operation:NSCompositeSourceOver];
    else
	[logBackground compositeToPoint:(rects.origin) operation:NSCompositeSourceOver];

    /*  COMPOSITE GRID, IF ASKED FOR  */
    if (gridDisplay) {
	if (magnitudeScale == LINEAR)
	    [linearGrid compositeToPoint:(rects.origin) operation:NSCompositeSourceOver];
	else
	    [logGrid compositeToPoint:(rects.origin) operation:NSCompositeSourceOver];
    }

    /*  COMPOSITE SPECTRUM  */
    [spectrum compositeToPoint:(rects.origin) operation:NSCompositeSourceOver];
}



/******************************************************************************
*
*	function:	dbValue
*
*	Purpose:	Converts a linear value between 0 and 1 to to a dB
*                       value, with 0 dB equal to unity gain, and lower
*			magnitudes equal to negative dB values.
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
