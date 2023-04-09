/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/WaveshapeView.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

 * Revision 1.1.1.1  1994/05/20  00:21:47  len
 * Initial archive of TRM interactive Synthesizer.
 *

******************************************************************************/

#import <AppKit/AppKit.h>

@interface WaveshapeView:NSView
{
    NSRect activeArea;
    id  background;
    id  foreground;
}

- initWithFrame:(NSRect)frameRect;
- (void)dealloc;

- (void)drawBackground;
- (void)drawSineAmplitude:(float)amplitude;
- (void)drawGlottalPulseAmplitude:(float)amplitude Scale:(float)scale RiseTime:(float)riseTime FallTimeMin:(float)fallTimeMin FallTimeMax:(float)fallTimeMax;

@end
