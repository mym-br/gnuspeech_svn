/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/CrossmixView.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

 * Revision 1.1.1.1  1994/05/20  00:21:54  len
 * Initial archive of TRM interactive Synthesizer.
 *

******************************************************************************/

#import <AppKit/AppKit.h>

@interface CrossmixView:NSView
{
    NSRect activeArea;
    id  background;
    id  foreground;
    id  volumeImage;

    int numberPoints;
    int numberCoords;
    int numberOps;
    float *coord;
    char *ops;
    float bbox[4];
}

- initWithFrame:(NSRect)frameRect;
- initializeUserPath;
- (void)dealloc;

- (void)drawLinearScale;
- (void)drawCrossmix:(int)crossmix;
- (void)drawNoCrossmix;
- (void)drawVolume:(int)volume;

@end

extern float pulsedGain(float volume, float crossmixOffset);
