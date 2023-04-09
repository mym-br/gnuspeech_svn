/*
 *    Filename:	SILText.m 
 *    Created :	Sun Jul  4 21:56:59 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Tue Jul 26 11:04:35 1994"
 *
 * $Id: SILText.m,v 1.4 1994/07/26 20:11:02 dale Exp $
 *
 * $Log: SILText.m,v $
 * Revision 1.4  1994/07/26  20:11:02  dale
 * *** empty log message ***
 *
 * Revision 1.3  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.2  1993/07/23  07:33:00  dale
 * *** empty log message ***
 *
 * Revision 1.1  1993/07/14  22:11:48  dale
 * Initial revision
 *
 * Revision 1.1  1993/07/06  00:34:26  dale
 * Initial revision
 *
 */

#import "Publisher.tproj.h"
#import "SILText.h"
#import "SILSpeaker.h"

@implementation SILText

/* This method is the designated initializer for the class. The default connection made to the TTS
 * Server by the message to super is freed since it is not a shared instance. We then create a shared
 * SIL speaker instance of the TTS Kit through the SILSpeaker subclass. We finally initialize the 
 * charWidth instance variable to correspond to the width of the default font. Returns self.
 */
- initFrame:(const NXRect *)frameRect text:(const char *)theText alignment:(int)mode
{
    NXCoord lMgn, rMgn, tMgn, bMgn;
    id font = [Font newFont:TNT_DEFAULT_FONT size:TNT_DEFAULT_FONT_SIZE];

    [super initFrame:frameRect text:theText alignment:mode];
    [speaker free];   // free TTS instance created; we want a shared SIL speaker instance
    speaker = [SILSpeaker new];

    // char width initialization
    charWidth = (int)ceil((double)[font getWidthOf:"O"]);

    // get rid of right margin
    [self getMarginLeft:&lMgn right:&rMgn top:&tMgn bottom:&bMgn];
    [self setMarginLeft:lMgn right:0.0 top:tMgn bottom:bMgn];
    return self;
}

/* This method overrides the inherited method. It Converts a point in the SIL (in the SIL text's
 * coordinate system) to a line and column equivalent. The column and line are adjusted since the 
 * window might not be EXACTLY the correct width or height. Essentially, we only convert to the 
 * calculated column and line if they are entirely visible. Otherwise wise we assign the values of the
 * column and line one less than the calculated values. Returns self.
 */
- convertPoint:(NXPoint *)aPoint toLine:(int *)line col:(int *)col
{
    NXCoord lMgn, rMgn, tMgn, bMgn;
    int columnsInSIL, linesInSIL;

    [self getMarginLeft:&lMgn right:&rMgn top:&tMgn bottom:&bMgn];
    *line = (aPoint->y - bounds.origin.y - tMgn) / [self lineHeight] + 1;
    *col = (aPoint->x - bounds.origin.x - lMgn) / charWidth + 1;
    columnsInSIL = (frame.size.width - lMgn - rMgn - 1.0) / charWidth;
    linesInSIL = (frame.size.height - tMgn - bMgn) / [self lineHeight];

    // adjust column for boundary cases
    if (*col < 1) {
	*col = 1;
    } else if (*col > columnsInSIL) {
	*col = columnsInSIL;
    } else if (*col >= TNT_SIL_COLUMNS) {
	*col = TNT_SIL_COLUMNS;
    }

    // adjust line for boundary cases
    if (*line < 1) {
	*line = 1;
    } else if (*line > linesInSIL) {
	*line = linesInSIL;
    } else if (*line >= TNT_SIL_LINES) {
	*line = TNT_SIL_LINES;
    }
    return self;
}

@end
