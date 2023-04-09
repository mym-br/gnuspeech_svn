/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/BandpassView.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

 * Revision 1.1.1.1  1994/05/20  00:21:53  len
 * Initial archive of TRM interactive Synthesizer.
 *

******************************************************************************/

#import <AppKit/AppKit.h>

@interface BandpassView:NSView
{
    NSRect activeArea;
    id  linearScale;
    id  logScale;
    id  foreground;

    int numberPoints;
    float *coord;
    char *ops;
    float bbox[4];
    float frequencyScale;
    float nyquistScale;

    int scale;
}

- initWithFrame:(NSRect)frameRect;
- initializeUserPath;
- (void)dealloc;

- (void)drawLinearScale;
- (void)drawLogScale;
- (void)drawCenterFrequency:(int)centerFrequency bandwidth:(int)bandwidth sampleRate:(float)sampleRate scale:(int)scale;

@end
