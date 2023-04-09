/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/AnalysisWindow.m,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

# Revision 1.1.1.1  1994/05/20  00:22:04  len
# Initial archive of TRM interactive Synthesizer.
#

******************************************************************************/

/*  HEADER FILES  ************************************************************/
#import "AnalysisWindow.h"
#import "sr_conversion.h"
#include <math.h>


/*  LOCAL DEFINES  ***********************************************************/
#define PI                 3.14159265358979
#define PI2                6.28318530717959


/*  GLOBAL FUNCTIONS (LOCAL TO THIS FILE)  ***********************************/
static void rectangularWindow(float *window, int windowSize);
static void triangularWindow(float *window, int windowSize);
static void hanningWindow(float *window, int windowSize);
static void hammingWindow(float *window, int windowSize, float alpha);
static void blackmanWindow(float *window, int windowSize);
static void kaiserWindow(float *window, int windowSize, float beta);



@implementation AnalysisWindow

- init
{
    /*  DO REGULAR INITIALIZATION  */
    [super init];

    /*  INITIALIZE DATA TO EMPTY  */
    window = NULL;
    windowSize = 0;

    return self;
}



- (void)dealloc
{
    /*  FREE BUFFER, IF NECESSARY  */
    [self freeWindow];

    /*  DO REGULAR FREE  */
    [super dealloc];
}



- (void)freeWindow
{
    /*  FREE BUFFER, IF NECESSARY  */
    if (window) {
	cfree((char *)window);
	windowSize = 0;
    } 
}



- (void)setWindowType:(int)type alpha:(float)alpha beta:(float)beta size:(int)size
{
    /*  FREE OLD BUFFER, IF NECESSARY  */
    [self freeWindow];

    /*  RETURN IMMEDIATELY IF SIZE ZERO OR LESS  */
    if (size <= 0)
	return;

    /*  SET WINDOW SIZE  */
    windowSize = size;

    /*  ALLOCATE THE WINDOW BUFFER  */
    window = (float *)calloc(windowSize, sizeof(float));

    /*  CREATE THE WINDOW  */
    switch (type) {
      case TRIANGULAR:
	triangularWindow(window, windowSize);
	break;
      case HANNING:
	hanningWindow(window, windowSize);
	break;
      case HAMMING:
	hammingWindow(window, windowSize, alpha);
	break;
      case BLACKMAN:
	blackmanWindow(window, windowSize);
	break;
      case KAISER:
	kaiserWindow(window, windowSize, beta);
	break;
      case RECTANGULAR:
      default:
	rectangularWindow(window, windowSize);
	break;
    } 
}



- (const float *)windowBuffer
{
    return (const float *)window;
}



- (int)windowSize
{
    return windowSize;
}



- (BOOL)haveWindow;
{
    if (window)
	return YES;
    else
	return NO;
}



/******************************************************************************
*
*	function:	rectangularWindow
*
*	purpose:	Creates a rectangular window.
*			
*       arguments:      window - memory buffer to write into.
*                       windowSize - size of the window.
*
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

void rectangularWindow(float *window, int windowSize)
{
    int i;

    for (i = 0; i < windowSize; i++)
	window[i] = 1.0;
}



/******************************************************************************
*
*	function:	triangularWindow
*
*	purpose:	Creates a triangular window
*			
*       arguments:      window - memory buffer to write into.
*                       windowSize - size of the window.
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

void triangularWindow(float *window, int windowSize)
{
    int i;
    float m = (float)(windowSize - 1);
    float midPoint = m / 2.0;
    float delta = 2.0 / m;

    /*  CREATE RISING PORTION  */
    for (i = 0; i < midPoint; i++)
	window[i] = delta * (float)i;

    /*  CREATE FALLING PORTION  */
    for ( ; i < windowSize; i++)
	window[i] = 2.0 - (delta * (float)i);
}



/******************************************************************************
*
*	function:	hanningWindow
*
*	purpose:	Creates a Hanning window.
*			
*       arguments:      window - memory buffer to write into.
*                       windowSize - size of the window.
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	cos
*
******************************************************************************/

void hanningWindow(float *window, int windowSize)
{
    int i;
    float m = (float)(windowSize - 1);
    float pi2divM = PI2 / m;

    for (i = 0; i < windowSize; i++)
	window[i] = 0.5 - (0.5 * cos(pi2divM * (float)i));
}



/******************************************************************************
*
*	function:	hammingWindow
*
*	purpose:	Creates a Hamming window
*                       
*			
*       arguments:      window - memory buffer to write into.
*                       windowSize - size of the window.
*                       alpha - window shape parameter.
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	cos
*
******************************************************************************/

void hammingWindow(float *window, int windowSize, float alpha)
{
    int i;
    float m = (float)(windowSize - 1);
    float pi2divM = PI2 / m;
    float alphaComplement = 1.0 - alpha;

    for (i = 0; i < windowSize; i++)
	window[i] = alpha - (alphaComplement * cos(pi2divM * (float)i));
}



/******************************************************************************
*
*	function:	blackmanWindow
*
*	purpose:	Creates a Blackman window
*			
*       arguments:      window - memory buffer to write into.
*                       windowSize - size of the window.
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	cos
*
******************************************************************************/

void blackmanWindow(float *window, int windowSize)
{
    int i;
    float m = (float)(windowSize - 1);
    float pi2divM = PI2 / m;
    float pi4divM = pi2divM * 2.0;

    for (i = 0; i < windowSize; i++)
	window[i] = 0.42 - (0.5 * cos(pi2divM * (float)i)) +
	    (0.08 * cos(pi4divM * (float)i));
}



/******************************************************************************
*
*	function:	kaiserWindow
*
*	purpose:	Creates a Kaiser window.
*
*       arguments:      window - memory buffer to write into.
*                       windowSize - size of the window.
*                       beta - window shape parameter.
*                       
*	internal
*	functions:	Izero
*
*	library
*	functions:	sqrt
*
******************************************************************************/

void kaiserWindow(float *window, int windowSize, float beta)
{
    int i;
    float m = (float)(windowSize - 1);
    float midPoint = m / 2.0;
    float IBeta = 1.0 / Izero(beta);

    for (i = 0; i < windowSize; i++) {
	float temp = ((float)i - midPoint) / midPoint;
	window[i] = Izero(beta * sqrt(1.0 - (temp*temp))) * IBeta;
    }
}

@end
