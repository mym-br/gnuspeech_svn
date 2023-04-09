/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/SpectrographView.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

 * Revision 1.1.1.1  1994/05/20  00:22:05  len
 * Initial archive of TRM interactive Synthesizer.
 *

******************************************************************************/

#import <AppKit/AppKit.h>

@interface SpectrographView:NSView
{
    NSRect activeArea;

    id  background;
    id  grid;
    id  spectrograph;

    id  crosshairCursor;
    id  frequencyDisplay;

    int   trackingTag;

    id    analysisDataObject;
    int   grayLevel;
    int   magnitudeScale;
    float linearUpperThreshold;
    float linearLowerThreshold;
    float logUpperThreshold;
    float logLowerThreshold;
    float linearRange;
    int   logRange;

    BOOL  gridDisplay;
}

- initWithFrame:(NSRect)frameRect;
- (void)dealloc;

- (void)resetCursorRects;
- (void)setFrameSize:(NSSize)_newSize;
- (void)setMouseTracking;
- (void)mouseEntered:(NSEvent *)e;
- (void)trackMouse:(NSPoint)mLoc;
- (void)stopTrackingMouse;
- (void)convertPoint:(NSPoint)location;

- (void)calculateActiveArea;
- (void)setGrid:(BOOL)flag;

- (void)drawBackground;
- (void)drawGrid;
- (void)displayAnalysis:analysisDataObj grayLevel:(int)grayLevelType magnitudeScale:(int)scaleType linearUpperThreshold:(float)linearUT linearLowerThreshold:(float)linearLT logUpperThreshold:(float)logUT logLowerThreshold:(float)logLT;
- (void)drawSpectrograph;

@end
