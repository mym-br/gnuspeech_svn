/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/ScaleView.m,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

# Revision 1.1.1.1  1994/05/20  00:21:42  len
# Initial archive of TRM interactive Synthesizer.
#

******************************************************************************/

/*  HEADER FILES  ************************************************************/
#import "ScaleView.h"
#import "GlottalSource.h"
#import "PSwraps.h"


/*  LOCAL DEFINES  ***********************************************************/
#define VOLUME_MAX         60.0

#define LEGER_LINE_WIDTH   12.0

#define STAFF_MARGIN       10.0
#define STAFF_SPACE        6.0
#define STAFF_INCREMENT    (STAFF_SPACE/2.0)

#define NOTE_WIDTH         STAFF_SPACE
#define NOTE_HEIGHT        STAFF_SPACE

#define SHARP_MARGIN       7.0
#define SHARP_WIDTH        7.0
#define SHARP_HEIGHT       14.0

#define ARROW_MARGIN       8.0
#define ARROW_WIDTH        6.0
#define ARROW_HEIGHT       10.0

#define POSITION          0
#define SHARP             1
#define ERROR             (-1)
#define SUCCESS           0
#define NOTE_NUMBER_MIN   (-24)
#define NOTE_NUMBER_MAX   24




@implementation ScaleView

- initWithFrame:(NSRect)frameRect
{
    /*  DO REGULAR INITIALIZATION  */
    [super initWithFrame:frameRect];

    /*  ALLOCATE A BACKGROUND NXIMAGE  */
    background = [[NSImage alloc] initWithSize:(frameRect.size)];

    /*  DRAW BACKGROUND  */
    [self drawBackground];

    /*  ALLOCATE A FORGROUND NXIMAGE  */
    foreground = [[NSImage alloc] initWithSize:(frameRect.size)];
    
    return self;
}



- (void)dealloc
{
    /*  FREE BACKGROUND NXIMAGE  */
    [background release];
    
    /*  FREE FOREGROUND NXIMAGE  */
    [foreground release];
    
    /*  DO REGULAR FREE  */
    { [super dealloc]; return; };
}


    
- (void)drawBackground
{
    float staffWidth, staffX, legerLineX, currentY;
    int i;


    /*  CALCULATE HORIZONTAL AND VERTICAL CENTER LINES  */
    horizontalCenter = NSWidth([self bounds]) / 2.0;
    verticalCenter = NSHeight([self bounds]) / 2.0;

    /*  CALCULATE STAFF WIDTH  */
    staffWidth = NSWidth([self bounds]) - (2.0 * STAFF_MARGIN);

    /*  CALCULATE STAFF X POINT  */
    staffX = NSMinX([self bounds]) + STAFF_MARGIN;

    /*  CALCULATE LEGER LINE X POINT  */
    legerLineX = horizontalCenter - (LEGER_LINE_WIDTH / 2.0);

    /*  CALCULATE VERTICAL CENTER LINE FOR SHARPS  */
    sharpCenter = horizontalCenter - NOTE_WIDTH/2.0 -
	          SHARP_MARGIN - SHARP_WIDTH/2.0;

    /*  CALCULATE VERTICAL CENTER LINE FOR ARROWS  */
    arrowCenter = horizontalCenter + NOTE_WIDTH/2.0 +
	          ARROW_MARGIN + ARROW_WIDTH/2.0;


    /*  LOCK FOCUS ON BACKGROUND NXIMAGE  */
    [background lockFocus];

    /*  DRAW WHITE BACKGROUND WITH BORDER  */
    NSDrawWhiteBezel([self bounds] , [self bounds]);

    /*  SET UP FOR DRAWING STAFF  */
    PSsetlinewidth(1.0);
    PSsetgray(NSBlack);

    /*  DRAW CENTER LEGER LINE  */
    PSmoveto(legerLineX, verticalCenter);
    PSrlineto(LEGER_LINE_WIDTH, 0.0);

    /*  DRAW LOWER STAFF  */
    for (i = 0, currentY = verticalCenter - STAFF_SPACE; i < 5;
	 i++, currentY -= STAFF_SPACE) {
	PSmoveto(staffX, currentY);
	PSrlineto(staffWidth, 0.0);
    }
    
    /*  DRAW BOTTOM TWO LEGER LINES  */
    for (i = 0; i < 2; i++, currentY -= STAFF_SPACE) {
	PSmoveto(legerLineX, currentY);
	PSrlineto(LEGER_LINE_WIDTH, 0.0);
    }

    /*  DRAW UPPER STAFF  */
    for (i = 0, currentY = verticalCenter + STAFF_SPACE; i < 5;
	 i++, currentY += STAFF_SPACE) {
	PSmoveto(staffX, currentY);
	PSrlineto(staffWidth, 0.0);
    }
    
    /*  DRAW TOP TWO LEGER LINES  */
    for (i = 0; i < 2; i++, currentY += STAFF_SPACE) {
	PSmoveto(legerLineX, currentY);
	PSrlineto(LEGER_LINE_WIDTH, 0.0);
    }

    /*  PAINT THE LINES  */
    PSstroke();

    /*  UNLOCK FOCUS ON BACKGROUND NXIMAGE  */
    [background unlockFocus]; 
}



- (void)drawPitch:(int)pitch Cents:(int)cents Volume:(float)volume
{
    int position, sharp, notePosition();
    float yPosition;

    /*  GET THE POSITION OF THE NOTE ON THE SCALE  */
    if (notePosition(pitch, &position, &sharp) == ERROR) {
	NSBeep();
	return;
    }

    /*  LOCK FOCUS ON THE FOREGROUND NXIMAGE  */
    [foreground lockFocus];

    /*  CLEAR THE NXIMAGE  */
    [foreground compositeToPoint:[self bounds].origin operation:NSCompositeClear];

    /*  SET THE GRAY LEVEL  */
    PSsetgray(NSLightGray + (volume/(float)VOLUME_MAX) * -NSLightGray);

    /*  CALCULATE CENTER Y POSITION OF NOTE, SHARP AND ARROWS  */
    yPosition = verticalCenter + ((float)position * STAFF_INCREMENT);

    /*  DRAW THE NOTE ON THE NXIMAGE  */
    PSnotehead(horizontalCenter, yPosition, NOTE_WIDTH, NOTE_HEIGHT);

    /*  DRAW SHARP, IF NECESSARY  */
    if (sharp)
	PSsharp(sharpCenter, yPosition, SHARP_WIDTH, SHARP_HEIGHT);

    /*  DRAW UP OR DOWN ARROW, IF NECESSARY  */
    if (cents > 0)
	PSuparrow(arrowCenter, yPosition, ARROW_WIDTH, ARROW_HEIGHT);
    else if (cents < 0)
	PSdownarrow(arrowCenter, yPosition, ARROW_WIDTH, ARROW_HEIGHT);

    /*  UNLOCK FOCUS ON THE FOREGROUND NXIMAGE  */
    [foreground unlockFocus];

    /*  DISPLAY THE NOTE, SHARP, AND ARROW  */
    [self display]; 
}



- (void)drawRect:(NSRect)rects
{
    /*  COMPOSITE THE FOREGROUND IMAGE OVER THE BACKGROUND  */
    [background compositeToPoint:(rects.origin) operation:NSCompositeSourceOver];
    [foreground compositeToPoint:(rects.origin) operation:NSCompositePlusDarker];
}



/******************************************************************************
*
*	function:	notePosition
*
*	purpose:	Returns the staff position and sharp flag for the
*                       given note number (semitone scale with middle C equal
*                       to 0).
*			
*       arguments:      noteNumber, position, sharp
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

int notePosition(int noteNumber, int *position, int *sharp)
{
    static int matrix[NOTE_NUMBER_MAX * 2 + 1][2] = {
	{-14,0}, {-14,1}, {-13,0}, {-13,1}, {-12,0}, {-11,0}, {-11,1},
	{-10,0}, {-10,1}, {-9, 0}, {-9, 1}, {-8, 0}, {-7, 0}, {-7, 1},
	{-6, 0}, {-6, 1}, {-5, 0}, {-4, 0}, {-4, 1}, {-3, 0}, {-3, 1},
	{-2, 0}, {-2, 1}, {-1, 0}, {0,  0}, {0,  1}, {1,  0}, {1,  1},
	{2,  0}, {3,  0}, {3,  1}, {4,  0}, {4,  1}, {5,  0}, {5,  1},
	{6,  0}, {7,  0}, {7,  1}, {8,  0}, {8,  1}, {9,  0}, {10, 0},
	{10, 1}, {11, 0}, {11, 1}, {12, 0}, {12, 1}, {13, 0}, {14, 0}
    };

    /*  MAKE SURE NOTE NUMBER IN RANGE  */
    if ((noteNumber < NOTE_NUMBER_MIN) || (noteNumber > NOTE_NUMBER_MAX)) {
	*position = *sharp = 0;
	return (ERROR);
    }

    /*  ADJUST NOTE NUMBER SO THAT MATRIX CAN BE INDEXED PROPERLY  */
    noteNumber += NOTE_NUMBER_MAX;

    /*  SET POSITION AND SHARP VALUES  */
    *position = matrix[noteNumber][POSITION];
    *sharp = matrix[noteNumber][SHARP];

    return (SUCCESS);
}	 

@end
