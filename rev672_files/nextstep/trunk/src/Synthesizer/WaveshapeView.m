/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/WaveshapeView.m,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

# Revision 1.1.1.1  1994/05/20  00:21:50  len
# Initial archive of TRM interactive Synthesizer.
#

******************************************************************************/

/*  HEADER FILES  ************************************************************/
#import "WaveshapeView.h"
#import "PSwraps.h"

/*  LOCAL DEFINES  ***********************************************************/
#define SIDE_MARGIN     10.0
#define TOP_MARGIN      10.0


@implementation WaveshapeView

- initWithFrame:(NSRect)frameRect
{
    /*  DO REGULAR INITIALIZATION  */
    [super initWithFrame:frameRect];

    /*  CALCULATE ACTIVE AREA  */
    activeArea = NSMakeRect(NSMinX([self bounds]), NSMinY([self bounds]), NSWidth([self bounds]), NSHeight([self bounds]));
    activeArea = NSInsetRect(activeArea , SIDE_MARGIN , TOP_MARGIN);

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
    /*  LOCK FOCUS ON BACKGROUND NXIMAGE  */
    [background lockFocus];

    /*  DRAW WHITE BACKGROUND WITH BORDER  */
    NSDrawWhiteBezel([self bounds] , [self bounds]);

    /*  DRAW LIGHT GRAY ENCLOSURE  */
    PSrectangle(NSMinX(activeArea), NSMinY(activeArea),
		NSWidth(activeArea), NSHeight(activeArea),
		1.0, NSLightGray);

    /*  DRAW CENTER LINE  */
    PSmoveto(NSMinX(activeArea), NSMidY(activeArea));
    PSrlineto(NSWidth(activeArea), 0.0);
    PSstroke();

    /*  UNLOCK FOCUS ON BACKGROUND NXIMAGE  */
    [background unlockFocus]; 
}



- (void)drawSineAmplitude:(float)amplitude
{
    /*  LOCK FOCUS ON THE FOREGROUND NXIMAGE  */
    [foreground lockFocus];

    /*  CLEAR THE NXIMAGE  */
    [foreground compositeToPoint:[self bounds].origin operation:NSCompositeClear];

    /*  DRAW THE SINE TONE WAVEFORM IN THE ACTIVE AREA  */
    PSsine(NSMinX(activeArea), NSMinY(activeArea),
	   NSWidth(activeArea), NSHeight(activeArea), amplitude);

    /*  UNLOCK FOCUS ON THE FOREGROUND NXIMAGE  */
    [foreground unlockFocus];

    /*  DISPLAY THE COMBINED IMAGES  */
    [self display]; 
}



- (void)drawGlottalPulseAmplitude:(float)amplitude Scale:(float)scale RiseTime:(float)riseTime FallTimeMin:(float)fallTimeMin FallTimeMax:(float)fallTimeMax
{
    /*  LOCK FOCUS ON THE FOREGROUND NXIMAGE  */
    [foreground lockFocus];

    /*  CLEAR THE NXIMAGE  */
    [foreground compositeToPoint:[self bounds].origin operation:NSCompositeClear];

    /*  DRAW THE GLOTTAL PULSE WAVEFORM IN THE ACTIVE AREA  */
    PSglottalpulse(NSMinX(activeArea), NSMinY(activeArea),
		   NSWidth(activeArea), NSHeight(activeArea), amplitude,
		   scale, riseTime, fallTimeMin, fallTimeMax);

    /*  UNLOCK FOCUS ON THE FOREGROUND NXIMAGE  */
    [foreground unlockFocus];

    /*  DISPLAY THE COMBINED IMAGES  */
    [self display]; 
}



- (void)drawRect:(NSRect)rects
{
    /*  COMPOSITE THE FOREGROUND IMAGE OVER THE BACKGROUND  */
    [background compositeToPoint:(rects.origin) operation:NSCompositeSourceOver];
    [foreground compositeToPoint:(rects.origin) operation:NSCompositeSourceOver];
}

@end
