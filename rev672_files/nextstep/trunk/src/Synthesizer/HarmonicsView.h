/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/HarmonicsView.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

 * Revision 1.1.1.1  1994/05/20  00:21:46  len
 * Initial archive of TRM interactive Synthesizer.
 *

******************************************************************************/

#import <AppKit/AppKit.h>

@interface HarmonicsView:NSView
{
    NSRect activeArea;
    id  linearGrid;
    id  logGrid;
    id  sineHarmonics;
    id  glottalPulseHarmonics;

    BOOL logScale;
    int harmonics;

    int numberHarmonics;
    int tableSize;
    float *wavetable;
}


- initWithFrame:(NSRect)frameRect;
- (void)dealloc;

- (void)drawLinearGrid;
- (void)drawLogGrid;
- (void)drawSineHarmonics;

- (void)drawSineScale:(BOOL)scale;
- (void)drawGlottalPulseAmplitude:(float)amplitude RiseTime:(float)riseTime FallTimeMin:(float)fallTimeMin FallTimeMax:(float)fallTimeMax Scale:(BOOL)scale;

@end
