/*  REVISION INFORMATION  *****************************************************

$Author: fedor $
$Date: 2003-01-18 05:04:50 $
$Revision: 1.2 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/ScaleView.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
Revision 1.1  2002/03/21 16:49:54  rao
Initial import.

 * Revision 1.1.1.1  1994/05/20  00:21:41  len
 * Initial archive of TRM interactive Synthesizer.
 *

******************************************************************************/

#import <AppKit/AppKit.h>

@interface ScaleView:NSView
{
    float horizontalCenter;
    float verticalCenter;
    float sharpCenter;
    float arrowCenter;

    id background;
    id foreground;
}

- initWithFrame:(NSRect)frameRect;
- (void)dealloc;

- (void)drawBackground;
- (void)drawPitch:(int)pitch Cents:(int)cents Volume:(float)volume;

@end
