/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/BandpassView.m,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

# Revision 1.1.1.1  1994/05/20  00:21:53  len
# Initial archive of TRM interactive Synthesizer.
#

******************************************************************************/

/*  HEADER FILES  ************************************************************/
#import "BandpassView.h"
#import "PSwraps.h"
#import <math.h>
#import <AppKit/NSGraphicsContext.h>


/*  LOCAL DEFINES  ***********************************************************/
#define SIDE_MARGIN        20.0
#define TOP_MARGIN         10.0
#define HORIZONTAL_LINES   4
#define VERTICAL_LINES     15
#define VERTICAL_NUM_SKIP  3
#define VERTICAL_NUM_LINES (VERTICAL_LINES/VERTICAL_NUM_SKIP)
#define NYQUIST_MAX        15000.0

#define LOG_SCALE_RANGE    70.0

#define FONT @"Helvetica"
#define FONT_SIZE          8.0
#define NUMBER_MARGIN      3.0

#define LINEAR_SCALE       0
#define LOG_SCALE          1

#define PI                 3.14159265358979
#define PI2                6.28318530717959


/*  GLOBAL FUNCTIONS (LOCAL TO THIS FILE)  ***********************************/
static float gain(float omega, float alpha, float beta, float gamma);

@implementation BandpassView

- initWithFrame:(NSRect)frameRect
{
    /*  DO REGULAR INITIALIZATION  */
    [super initWithFrame:frameRect];

    /*  CALCULATE ACTIVE AREA  */
    activeArea = NSMakeRect(NSMinX([self bounds]), NSMinY([self bounds]), NSWidth([self bounds]), NSHeight([self bounds]));
    activeArea = NSInsetRect(activeArea , SIDE_MARGIN , TOP_MARGIN + (0.5 * TOP_MARGIN));
    activeArea = NSOffsetRect(activeArea , 0.0 , (0.5 * TOP_MARGIN));

    /*  CALCULATE NUMBER OF GRAPHING POINTS  */
    numberPoints = (int)NSWidth(activeArea);

    /*  ALLOCATE MEMORY FOR USER PATH  */
    coord = (float *)calloc(((numberPoints + 1) * 2), sizeof(float));

    /*  INITIALIZE USER PATH  */
    [self initializeUserPath];

    /*  ALLOCATE BACKGROUND NXIMAGES  */
    linearScale = [[NSImage alloc] initWithSize:(frameRect.size)];
    logScale = [[NSImage alloc] initWithSize:(frameRect.size)];

    /*  DRAW BACKGROUNDS  */
    [self drawLinearScale];
    [self drawLogScale];

    /*  ALLOCATE A FORGROUND NXIMAGE  */
    foreground = [[NSImage alloc] initWithSize:(frameRect.size)];
    
    return self;
}



- initializeUserPath
{
    int i;

    /*  INITIALIZE X COORDINATES OF PATH  */
    for (i = 0; i <= numberPoints; i++)
	coord[i*2] = NSMinX(activeArea) + (float)i;

    /*  INITIALIZE BEGIN Y COORDINATE OF PATH  */
    coord[1] = NSMinY(activeArea);

    /*  SET THE BOUNDING BOX FOR THE USER PATH  */
    bbox[0] = NSMinX(activeArea);
    bbox[1] = NSMinY(activeArea);
    bbox[2] = NSMaxX(activeArea);
    bbox[3] = NSMaxY(activeArea);

    /*  CALCULATE FREQUENCY AND NYQUIST SCALES  */
    frequencyScale = NYQUIST_MAX / (float)numberPoints;
    nyquistScale = frequencyScale * PI;

    return self;
}



- (void)dealloc
{
    /*  FREE BACKGROUND NXIMAGES  */
    [linearScale release];
    [logScale release];

    /*  FREE FOREGROUND NXIMAGE  */
    [foreground release];

    /*  FREE USER PATH ARRAYS  */
    cfree(coord);
    
    /*  DO REGULAR FREE  */
    [super dealloc]; 
}



- (void)drawLinearScale
{
    float verticalIncrement, horizontalIncrement, dx, px, py;
    int i;
    NSFont *fontObject1; 

    /*  LOCK FOCUS ON LINEAR SCALE NXIMAGE  */
    [linearScale lockFocus];

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
	PSstringwidth(number, &px, &py);

	PSmoveto(NSMinX(activeArea) - px - NUMBER_MARGIN,
		 NSMinY(activeArea) + ((float)i * verticalIncrement)
		 - FONT_SIZE / 2.0 + 1.0);

	/*  DRAW THE NUMBER ON THE GRID  */
	PSshow(number);
    }

    /*  NUMBER VERTICAL LINES  */
    horizontalIncrement = NYQUIST_MAX / VERTICAL_NUM_LINES;
    dx = NSWidth(activeArea) / VERTICAL_NUM_LINES;
    for (i = 0; i <= VERTICAL_NUM_LINES; i++) {
	char number[12];
	
	/*  FORMAT THE NUMBER  */
	sprintf(number, "%-d", i * (int)horizontalIncrement);
	
	/*  DETERMINE STRING WIDTH  */
	PSstringwidth(number, &px, &py);
	
	/*  PLACE STRING IN APPROPRIATE PLACE  */
	PSmoveto(NSMinX(activeArea) + (float)i * dx - px/2.0,
		 NSMinY(activeArea) - FONT_SIZE - NUMBER_MARGIN);
	
	/*  WRITE STRING TO VIEW  */
	PSshow(number);
    }

    /*  UNLOCK FOCUS ON LINEARSCALE NXIMAGE  */
    [linearScale unlockFocus]; 
}



- (void)drawLogScale
{
    float verticalIncrement, horizontalIncrement, dx, px, py;
    int i, verticalLines;
    NSFont *fontObject1; 

    /*  LOCK FOCUS ON LOG SCALE NXIMAGE  */
    [logScale lockFocus];

    /*  SET UP FONT  */
    fontObject1 = [NSFont fontWithName: FONT size: FONT_SIZE];

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
    for (i = 0; i <= verticalLines; i++) {
	char number[12];
	int numberValue = -(i * 10);

	/*  FORMAT THE NUMBER  */
	sprintf(number, "%-d", numberValue);

	/*  DETERMINE STRING WIDTH  */
	PSstringwidth(number, &px, &py);

	PSmoveto(NSMinX(activeArea) - px - NUMBER_MARGIN,
		 NSMaxY(activeArea) - ((float)i * verticalIncrement)
		 - FONT_SIZE / 2.0 + 1.0);

	/*  DRAW THE NUMBER ON THE GRID  */
	PSshow(number);
    }

    /*  NUMBER VERTICAL LINES  */
    horizontalIncrement = NYQUIST_MAX / VERTICAL_NUM_LINES;
    dx = NSWidth(activeArea) / VERTICAL_NUM_LINES;
    for (i = 0; i <= VERTICAL_NUM_LINES; i++) {
	char number[12];
	
	/*  FORMAT THE NUMBER  */
	sprintf(number, "%-d", i * (int)horizontalIncrement);
	
	/*  DETERMINE STRING WIDTH  */
 	PSstringwidth(number, &px, &py);
	
	/*  PLACE STRING IN APPROPRIATE PLACE  */
	PSmoveto(NSMinX(activeArea) + (float)i * dx - px/2.0,
		 NSMinY(activeArea) - FONT_SIZE - NUMBER_MARGIN);
	
	/*  WRITE STRING TO VIEW  */
	PSshow(number);
    }

    /*  UNLOCK FOCUS ON LOG SCALE NXIMAGE  */
    [logScale unlockFocus]; 
}



- (void)drawCenterFrequency:(int)centerFrequency bandwidth:(int)bandwidth sampleRate:(float)sampleRate scale:(int)backgroundScale;
{
    float alpha, beta, gamma, theta, thetaDelta, pi2divSampleRate;
    float tanThetaDeltaDiv2, nyquist;
    int i, nyquistPoint;

    /*  RECORD WHICH SCALE TO USE  */
    scale = backgroundScale;

    /*  CALCULATE NYQUIST AND NYQUIST GRAPHING POINT  */
    nyquist = sampleRate / 2.0;
    nyquistPoint = (int)(nyquist / frequencyScale);

    /*  LOCK FOCUS ON THE FOREGROUND NXIMAGE  */
    [foreground lockFocus];

    /*  CLEAR THE NXIMAGE  */
    [foreground compositeToPoint:[self bounds].origin operation:NSCompositeClear];

    /*  CALCULATE FILTER COEFFICIENTS  */
    pi2divSampleRate = PI2 / sampleRate;
    thetaDelta = (float)bandwidth * pi2divSampleRate;
    theta = (float)centerFrequency * pi2divSampleRate;
    tanThetaDeltaDiv2 = tan(thetaDelta/2.0);

    beta = 0.5 * (1.0 - tanThetaDeltaDiv2) / (1.0 + tanThetaDeltaDiv2);
    gamma = (0.5 + beta) * cos(theta);
    alpha = (0.5 - beta) / 2.0;

    /*  CALCULATE THE FREQUENCY RESPONSE  */
    if (scale == LINEAR_SCALE) {
	for (i = 1; i <= nyquistPoint; i++) {
	    coord[(i*2)+1] = NSMinY(activeArea) +
		(NSHeight(activeArea) *
		 gain(((float)i * nyquistScale)/nyquist, alpha, beta, gamma));
	}
	/*  MAKE SURE END OF LINE IS AT ZERO  */
	coord[((nyquistPoint+1)*2)+1] = NSMinY(activeArea);
    }
    else if (scale == LOG_SCALE) {
	for (i = 1; i <= nyquistPoint; i++) {
	    float dB = log10(gain(((float)i * nyquistScale)/nyquist,
				  alpha, beta, gamma)) * 20.0;
	    dB = (dB < -LOG_SCALE_RANGE) ? -LOG_SCALE_RANGE : dB;
	    coord[(i*2)+1] = NSMaxY(activeArea) +
		(NSHeight(activeArea) * dB/LOG_SCALE_RANGE);
	}
	/*  MAKE SURE END OF LINE IS AT ZERO  */
	coord[((nyquistPoint+1)*2)+1] = NSMinY(activeArea);
    }

    /*  TRACE USER PATH ON FOREGROUND NXIMAGE  */
    PSsetgray(NSBlack);
    PSDoUserPath(coord, (nyquistPoint+2), 1);

    /*  UNLOCK FOCUS ON THE FOREGROUND NXIMAGE  */
    [foreground unlockFocus];

    /*  DISPLAY THE COMBINED IMAGES  */
    [self display];
}



- (void)drawRect:(NSRect)rects
{
    /*  COMPOSITE THE FOREGROUND IMAGE OVER APPROPRIATE BACKGROUND  */
    if (scale == LINEAR_SCALE)
	[linearScale compositeToPoint:(rects.origin) operation:NSCompositeSourceOver];
    else
	[logScale compositeToPoint:(rects.origin) operation:NSCompositeSourceOver];

    /*  COMPOSITE FOREGROUND IMAGE  */
    [foreground compositeToPoint:(rects.origin) operation:NSCompositeSourceOver];
}



/******************************************************************************
*
*	function:	gain
*
*	purpose:	Returns the gain of the bandpass filter (a value from
*                       0.0 to 1.0) according to the filter coefficients
*                       alpha, beta, and gamma, at the frequency omega (which
*                       varies from 0 to Pi).
*			
*       arguments:      omega - value from 0 to Pi (Nyquist)
*                       alpha, beta, gamma - filter coefficients
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	cos, sin, sqrt
*
******************************************************************************/

float gain(float omega, float alpha, float beta, float gamma)
{
    float a, b, c, d;
    float omega2, alpha2, beta2, gamma2, cosOmega2, sinOmega2;

    omega2 = 2.0 * omega;
    alpha2 = 2.0 * alpha;
    beta2 = 2.0 * beta;
    gamma2 = 2.0 * gamma;
    cosOmega2 = cos(omega2);
    sinOmega2 = sin(omega2);

    a = alpha2 - alpha2 * cosOmega2;
    b = alpha2 * sinOmega2;
    c = 1.0 - gamma2 * cos(omega) + beta2 * cosOmega2;
    d = gamma2 * sin(omega) - beta2 * sinOmega2;

    return( sqrt((a * a) + (b * b)) / sqrt((c * c) + (d * d)) );
}
@end

