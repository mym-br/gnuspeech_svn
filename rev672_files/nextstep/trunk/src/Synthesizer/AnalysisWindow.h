/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/AnalysisWindow.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

 * Revision 1.1.1.1  1994/05/20  00:22:03  len
 * Initial archive of TRM interactive Synthesizer.
 *

******************************************************************************/

/*  HEADER FILES  ************************************************************/
#import <AppKit/AppKit.h>


/*  GLOBAL DEFINES  **********************************************************/
#define RECTANGULAR           0
#define TRIANGULAR            1
#define HANNING               2
#define HAMMING               3
#define BLACKMAN              4
#define KAISER                5



@interface AnalysisWindow:NSObject
{
    float *window;
    int   windowSize;
}

- init;
- (void)dealloc;
- (void)freeWindow;

- (void)setWindowType:(int)type alpha:(float)alpha beta:(float)beta size:(int)size;
- (const float *)windowBuffer;
- (int)windowSize;
- (BOOL)haveWindow;

@end
