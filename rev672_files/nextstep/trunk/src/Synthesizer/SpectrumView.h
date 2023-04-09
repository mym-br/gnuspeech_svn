/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/SpectrumView.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

 * Revision 1.1.1.1  1994/05/20  00:22:06  len
 * Initial archive of TRM interactive Synthesizer.
 *

******************************************************************************/

#import <AppKit/AppKit.h>


@interface SpectrumView:NSView
{
    NSRect activeArea;

    id  linearBackground;
    id  logBackground;
    id  linearGrid;
    id  logGrid;
    id  spectrum;

    id  crosshairCursor;
    id  frequencyDisplay;
    id  magnitudeDisplay;

    int trackingTag;

    id  analysisDataObject;
    int magnitudeScale;

    BOOL gridDisplay;

    char *ops;
    float *coord;
    float bbox[4];
    float dbScale;
}

- initWithFrame:(NSRect)frameRect;
- (void)dealloc;

- initializeUserPath;
- (void)freeUserPath;
- (void)resetUserPath;

- (void)resetCursorRects;
- (void)setFrameSize:(NSSize)_newSize;
- (void)setMouseTracking;
- (void)mouseEntered:(NSEvent *)e;
- (void)trackMouse:(NSPoint)mLoc;
- (void)stopTrackingMouse;
- (void)convertPoint:(NSPoint)location;

- (void)calculateActiveArea;
- (void)setGrid:(BOOL)flag;

- (void)drawLinearBackground;
- (void)drawLogBackground;
- (void)drawLinearGrid;
- (void)drawLogGrid;
- (void)displayAnalysis:analysisDataObj magnitudeScale:(int)scaleType;
- (void)drawSpectrum;

@end
