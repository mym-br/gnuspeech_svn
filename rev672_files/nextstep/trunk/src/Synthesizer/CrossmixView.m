/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/CrossmixView.m,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

# Revision 1.1.1.1  1994/05/20  00:21:55  len
# Initial archive of TRM interactive Synthesizer.
#

******************************************************************************/

/*  HEADER FILES  ************************************************************/
#import "CrossmixView.h"
#import "GlottalSource.h"
#import "PSwraps.h"
#import "conversion.h"
#import <AppKit/NSGraphicsContext.h>
#include <math.h>


/*  LOCAL DEFINES  ***********************************************************/
#define SIDE_MARGIN        10.0
#define TOP_MARGIN         10.0
#define HORIZONTAL_LINES   4
#define VERTICAL_LINES     6

#define FONT @"Helvetica"
#define FONT_SIZE          8.0
#define NUMBER_MARGIN      3.0
#define LABEL_FONT_SIZE    10.0
#define LABEL_MARGIN       5.0



@implementation CrossmixView

- initWithFrame:(NSRect)frameRect
{
    /*  DO REGULAR INITIALIZATION  */
    [super initWithFrame:frameRect];

    /*  CALCULATE ACTIVE AREA  */
    activeArea = NSMakeRect(NSMinX([self bounds]), NSMinY([self bounds]), NSWidth([self bounds]), NSHeight([self bounds]));
    activeArea = NSInsetRect(activeArea , SIDE_MARGIN + (0.5 * SIDE_MARGIN) , TOP_MARGIN + (0.5 * TOP_MARGIN));
    activeArea = NSOffsetRect(activeArea , (0.5 * SIDE_MARGIN) , (0.5 * TOP_MARGIN));

    /*  CALCULATE NUMBER OF GRAPHING POINTS, COORDINATES, & OPERATORS  */
    numberPoints = (int)NSWidth(activeArea);
    numberOps = numberPoints + 1;
    numberCoords = numberOps * 2;

    /*  ALLOCATE MEMORY FOR USER PATH  */
    coord = (float *)calloc(numberCoords, sizeof(float));

    /*  INITIALIZE USER PATH  */
    [self initializeUserPath];

    /*  ALLOCATE BACKGROUND NXIMAGE  */
    background = [[NSImage alloc] initWithSize:(frameRect.size)];

    /*  DRAW BACKGROUND  */
    [self drawLinearScale];

    /*  ALLOCATE A FORGROUND NXIMAGE  */
    foreground = [[NSImage alloc] initWithSize:(frameRect.size)];
    
    /*  ALLOCATE A NXIMAGE FOR DISPLAYING VOLUME  */
    volumeImage = [[NSImage alloc] initWithSize:(frameRect.size)];
    
    return self;
}



- initializeUserPath
{
    int i;

    /*  INITIALIZE X COORDINATES OF PATH  */
    for (i = 0; i <= numberPoints; i++)
	coord[i*2] = NSMinX(activeArea) + (float)i;

    /*  SET THE BOUNDING BOX FOR THE USER PATH  */
    bbox[0] = NSMinX(activeArea);
    bbox[1] = NSMinY(activeArea);
    bbox[2] = NSMaxX(activeArea);
    bbox[3] = NSMaxY(activeArea);

    return self;
}



- (void)dealloc
{
    /*  FREE BACKGROUND NXIMAGE  */
    [background release];

    /*  FREE FOREGROUND NXIMAGE  */
    [foreground release];

    /*  FREE VOLUME NXIMAGE  */
    [volumeImage release];

    /*  FREE USER PATH ARRAYS  */
    cfree(coord);
    
    /*  DO REGULAR FREE  */
    { [super dealloc]; return; };
}



- (void)drawLinearScale
{
    float verticalIncrement, horizontalIncrement;
    int i;
    NSSize p;
    NSString *str;
    NSFont *fontObject1;

    /*  LOCK FOCUS ON BACKGROUND NXIMAGE  */
    [background lockFocus];

    /*  SET UP FONT  */
   fontObject1 = [NSFont fontWithName: FONT size: FONT_SIZE];

    /*  DRAW WHITE BACKGROUND WITH BORDER  */
    NSDrawWhiteBezel([self bounds] , [self bounds]);

    /*  DRAW LIGHT GRAY ENCLOSURE  */
    PSrectangle(NSMinX(activeArea), NSMinY(activeArea),
		NSWidth(activeArea), NSHeight(activeArea),
		1.0, NSLightGray);

    /*  DRAW HORIZONTAL LINES  */
    verticalIncrement = NSHeight(activeArea) / (float)HORIZONTAL_LINES;
    for (i = 1; i < HORIZONTAL_LINES; i++) {
	PSmoveto(NSMinX(activeArea),
		 NSMinY(activeArea) + ((float)i * verticalIncrement));
	PSrlineto(NSWidth(activeArea), 0.0);
    }

    /*  DRAW VERTICAL LINES  */
    horizontalIncrement = NSWidth(activeArea) / (float)VERTICAL_LINES;
    for (i = 1; i < VERTICAL_LINES; i++) {
	PSmoveto(NSMinX(activeArea) + ((float)i * horizontalIncrement),
		 NSMinY(activeArea));
	PSrlineto(0.0, NSHeight(activeArea));
    }
    PSstroke();

    /*  NUMBER HORIZONTAL LINES  */
    [fontObject1 set];
    PSsetgray(NSBlack);
    for (i = 0; i <= HORIZONTAL_LINES; i++) {
	char number[12];
	int scaledNumber;
	float value = (float)i/(float)HORIZONTAL_LINES;

	/*  FORMAT THE NUMBER  */
	scaledNumber = (int)(100.0 * value);
	if (!(scaledNumber % 100))
	    sprintf(number, "%-d", (int)value);
	else if (!(scaledNumber % 50))
	    sprintf(number, ".%-d", scaledNumber/10);
	else
	    sprintf(number, ".%-d", scaledNumber);

	/*  DETERMINE STRING WIDTH  */
	str = [NSString stringWithCString: number];
	p = [str sizeWithAttributes: nil];

	PSmoveto(NSMinX(activeArea) - p.width - NUMBER_MARGIN,
		 NSMinY(activeArea) + ((float)i * verticalIncrement)
		 - FONT_SIZE / 2.0 + 1.0);

	/*  DRAW THE NUMBER ON THE GRID  */
	PSshow(number);
    }

    /*  NUMBER VERTICAL LINES  */
    for (i = 0; i <= VERTICAL_LINES; i++) {
	char number[12];
	float value = (float)i/(float)VERTICAL_LINES * VOLUME_MAX;

	/*  FORMAT THE NUMBER  */
	sprintf(number, "%-d", (int)value);

	/*  DETERMINE STRING WIDTH  */
	str = [NSString stringWithCString: number];
	p = [str sizeWithAttributes: nil];

	PSmoveto(NSMinX(activeArea) + (float)i * horizontalIncrement - p.width/2.0,
		 NSMinY(activeArea) - FONT_SIZE - NUMBER_MARGIN);

	/*  DRAW THE NUMBER ON THE GRID  */
	PSshow(number);
    }

    /*  UNLOCK FOCUS ON background NXIMAGE  */
    [background unlockFocus]; 
}



- (void)drawCrossmix:(int)crossmix
{
    int i, endPosition;
    NSSize p;
    NSString *str;
    NSFont *fontObject1;

    /*  LOCK FOCUS ON THE FOREGROUND NXIMAGE  */
    [foreground lockFocus];

    /*  CLEAR THE NXIMAGE  */
    [foreground compositeToPoint:[self bounds].origin operation:NSCompositeClear];

    /*  SET UP FONT FOR LABELS */
    fontObject1 = [NSFont fontWithName: FONT size: LABEL_FONT_SIZE];
    [fontObject1 set];

    /*  CALCULATE PULSED NOISE PATH  */
    for (i = 0; i <= numberPoints; i++)
	coord[(i*2)+1] = NSMinY(activeArea) + (NSHeight(activeArea) *
            pulsedGain(VOLUME_MAX * (float)i/(float)numberPoints,
		       (float)crossmix));

    /*  TRACE USER PATH ON FOREGROUND NXIMAGE  */
    PSsetgray(NSBlack);
    PSDoUserPath(coord, numberOps, 1);

    /*  DRAW "PULSED" LABEL  */
    str = @"Pulsed";
    p = [str sizeWithAttributes: nil];
    endPosition = (int)(p.width + LABEL_MARGIN);
    PSmoveto(NSMinX(activeArea) + LABEL_MARGIN,
	     floor(coord[(endPosition*2)+1]) + LABEL_MARGIN);
    PSshow("Pulsed");

    /*  CALCULATE PURE NOISE PATH  */
    for (i = 0; i <= numberPoints; i++)
	coord[(i*2)+1] = NSMinY(activeArea) + (NSHeight(activeArea) * (1.0 -
          pulsedGain(VOLUME_MAX * (float)i/(float)numberPoints,
		     (float)crossmix)));

    /*  TRACE USER PATH ON FOREGROUND NXIMAGE  */
    PSDoUserPath(coord, numberOps, 1);

    /*  DRAW "PURE" LABEL  */
    str = @"Pure";
    p = [str sizeWithAttributes: nil];
    endPosition = (int)(p.width + LABEL_MARGIN);
    PSmoveto(NSMinX(activeArea) + LABEL_MARGIN,
	     ceil(coord[(endPosition*2)+1]) - LABEL_MARGIN - FONT_SIZE);
    PSshow("Pure");

    /*  UNLOCK FOCUS ON THE FOREGROUND NXIMAGE  */
    [foreground unlockFocus];

    /*  DISPLAY THE COMBINED IMAGES  */
    [self display]; 
}



- (void)drawNoCrossmix
{
    NSFont *fontObject1;

    /*  LOCK FOCUS ON THE FOREGROUND NXIMAGE  */
    [foreground lockFocus];

    /*  CLEAR THE NXIMAGE  */
    [foreground compositeToPoint:[self bounds].origin operation:NSCompositeClear];

    /*  SET UP FONT FOR LABELS */
    fontObject1 = [NSFont fontWithName: FONT size: LABEL_FONT_SIZE];
    [fontObject1 set];

    /*  DRAW PURE NOISE LINE  */
    PSsetgray(NSBlack);
    PSmoveto(NSMinX(activeArea), NSMaxY(activeArea));
    PSrlineto(NSWidth(activeArea), 0.0);

    /*  DRAW "PURE" LABEL  */
    PSmoveto(NSMinX(activeArea) + LABEL_MARGIN,
	     NSMaxY(activeArea) - LABEL_MARGIN - FONT_SIZE);
    PSshow("Pure");

    /*  DRAW PULSED NOISE LINE  */
    PSsetgray(NSBlack);
    PSmoveto(NSMinX(activeArea), NSMinY(activeArea));
    PSrlineto(NSWidth(activeArea), 0.0);
    PSstroke();

    /*  DRAW "PULSED" LABEL  */
    PSmoveto(NSMinX(activeArea) + LABEL_MARGIN,
	     NSMinY(activeArea) + LABEL_MARGIN);
    PSshow("Pulsed");

    /*  UNLOCK FOCUS ON THE FOREGROUND NXIMAGE  */
    [foreground unlockFocus];

    /*  DISPLAY THE COMBINED IMAGES  */
    [self display]; 
}



- (void)drawVolume:(int)volume
{
    /*  LOCK FOCUS ON THE VOLUME NXIMAGE  */
    [volumeImage lockFocus];

    /*  CLEAR THE NXIMAGE  */
    [volumeImage compositeToPoint:[self bounds].origin operation:NSCompositeClear];

    /*  DRAW VERTICAL LINE WHICH CORRESPONDS TO VOLUME  */
    PSsetgray(NSDarkGray);
    PSmoveto(NSMinX(activeArea) + (float)volume/(float)VOLUME_MAX *
	     NSWidth(activeArea), NSMinY(activeArea));
    PSrlineto(0.0, NSHeight(activeArea));
    PSstroke();

    /*  UNLOCK FOCUS ON THE VOLUME NXIMAGE  */
    [volumeImage unlockFocus];

    /*  DISPLAY THE COMBINED IMAGES  */
    [self display]; 
}



- (void)drawRect:(NSRect)rects
{
    /*  COMPOSITE THE FOREGROUND IMAGE OVER APPROPRIATE BACKGROUND  */
    [background compositeToPoint:(rects.origin) operation:NSCompositeSourceOver];

    /*  COMPOSITE VOLUME IMAGE  */
    [volumeImage compositeToPoint:(rects.origin) operation:NSCompositeSourceOver];

    /*  COMPOSITE FOREGROUND IMAGE  */
    [foreground compositeToPoint:(rects.origin) operation:NSCompositePlusDarker];
}



/******************************************************************************
*
*	function:	pulsedGain
*
*	purpose:	Returns the gain of the pulsed noise, for a given
*                       volume (in dB) and crossmix offset (in dB).
*			
*       arguments:      volume, crossmixOffset
*                       
*	internal
*	functions:	amplitude
*
*	library
*	functions:	none
*
******************************************************************************/

float pulsedGain(float volume, float crossmixOffset)
{
    float gain = amplitude((double)volume) / amplitude((double)crossmixOffset);
    gain = (gain > 1.0) ? 1.0 : gain;
    return (gain);
}
@end
