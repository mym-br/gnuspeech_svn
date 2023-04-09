/*
 *    Filename:	Page.m 
 *    Created :	Wed May 19 14:37:16 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Wed Jun 29 15:33:42 1994"
 *
 * $Id: Page.m,v 1.14 1994/06/29 22:39:07 dale Exp $
 *
 * $Log: Page.m,v $
 * Revision 1.14  1994/06/29  22:39:07  dale
 * Overrided default -moveBy:: to automatically adjust topmost visible line and leftmost visible
 * column, in addition to doing the normal thing. It should no longer be necessary for set... methods
 * for these instance variables to be used.
 *
 * Revision 1.13  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.12  1993/08/27  03:51:06  dale
 * Added methods to start and stop cursor blinking.
 *
 * Revision 1.11  1993/07/23  07:33:00  dale
 * *** empty log message ***
 *
 * Revision 1.10  1993/07/14  22:11:48  dale
 * *** empty log message ***
 *
 * Revision 1.9  1993/07/04  17:57:23  dale
 * *** empty log message ***
 *
 * Revision 1.8  1993/06/25  23:38:25  dale
 * Added bookmarkNumber for dealing with default bookmark names.
 *
 * Revision 1.7  1993/06/24  07:40:50  dale
 * Added cursor drawing in -drawSelf::. Also moved some methods from TactileDisplay to here.
 *
 * Revision 1.6  1993/06/18  08:45:44  dale
 * Removed right margin.
 *
 * Revision 1.5  1993/06/05  07:37:08  dale
 * *** empty log message ***
 *
 * Revision 1.4  1993/06/03  00:37:58  dale
 * *** empty log message ***
 *
 * Revision 1.3  1993/06/01  08:03:24  dale
 * *** empty log message ***
 *
 * Revision 1.2  1993/05/30  08:24:27  dale
 * *** empty log message ***
 *
 * Revision 1.1  1993/05/20  06:03:35  dale
 * Initial revision
 *
 */

#import "TNTDefinitions.h"
#import "Document.h"
#import "Page.h"

/* System cursor and mark image names. */
#define SYSTEM_CURSOR_IMAGE "SystemCursor.tiff"
#define MARK_IMAGE "Mark.tiff"

@implementation Page

static void blinkSystemCursor(DPSTimedEntry tag, double now, Page *self)
{
    [self setSystemCursorOnScreen:![self systemCursorOnScreen]];   // toggle on screen value
    [self lockFocus];
    PSsetinstance(YES);      // turn on instance drawing
    PSnewinstance();         // erase all previous instance drawing
    [self updateSystemCursor];
    [self updateMark];       // mark must be redrawn if we just erased it
    [self showUserCursor];   // user cursor might have to be redrawn if we just erased it
    PSsetinstance(NO);       // turn off instance drawing
    [self unlockFocus];
}

static void blinkMark(DPSTimedEntry tag, double now, Page *self)
{
    [self setMarkOnScreen:![self markOnScreen]];   // toggle on screen value
    [self lockFocus];
    PSsetinstance(YES);          // turn on instance drawing
    PSnewinstance();             // erase all previous instance drawing
    [self updateMark];
    [self updateSystemCursor];   // system cursor must be redrawn if we just erased it
    [self showUserCursor];       // user cursor might have to be redrawn if we just erased it
    PSsetinstance(NO);           // turn off instance drawing
    [self unlockFocus];
}


/* INITIALIZING AND FREEING *************************************************************************/


/* This method is the designated initializer for the class. Note, the Page object defaults to normal
 * page margins for text objects, except that the right margin is set to 0.0. Returns self.
 */
- initFrame:(const NXRect *)frameRect text:(const char *)theText alignment:(int)mode
{
    NXCoord lMgn, rMgn, tMgn, bMgn;

    [super initFrame:frameRect text:theText alignment:mode];

    // get rid of right margin
    [self getMarginLeft:&lMgn right:&rMgn top:&tMgn bottom:&bMgn];
    [self setMarginLeft:lMgn right:0.0 top:tMgn bottom:bMgn];

    // initialize page locations
    leftVisibleCol = 1;
    topVisibleLine = 1;
    pageNumber = 1;
    pageNode = nil;
    
    // initialize master document
    masterDocument = nil;

    // initialize timed-entry handles
    systemCursorTE = (DPSTimedEntry)0;
    markTE = (DPSTimedEntry)0;

    // initialize cursor screen status (pretend they are visible to avoid initial flicker)
    systemCursorOnScreen = YES;
    markOnScreen = YES;

    // get cursor images
    systemCursor = [NXImage findImageNamed:SYSTEM_CURSOR_IMAGE];
    mark = [NXImage findImageNamed:MARK_IMAGE];
    return self;
}

- initFrame:(const NXRect *)frameRect
{
    return [self initFrame:frameRect text:NULL alignment:NX_LEFTALIGNED];
}

/* Removes all cursor related timed-entries. Nothing else needs to be freed, that is, nodes are freed
 * elsewhere (when node lists are freed).
 */
- free
{
    // remove system cursor timed-entry
    if (systemCursorTE) {
	DPSRemoveTimedEntry(systemCursorTE);
	systemCursorTE = (DPSTimedEntry)0;
    }
    // remove mark timed-entry
    if (markTE) {
	DPSRemoveTimedEntry(markTE);
	markTE = (DPSTimedEntry)0;
    }
    return [super free];
}


/* ADJUSTMENT METHODS *******************************************************************************/


/* Resets our position such that we are positioned within the scroll view with the left margin and top
 * margin coincident with the left side and top side of the scroll view respectively. We convert the
 * bounds rectangle to our superview's superview's coordinate system (normally a scroll view). The top
 * visible line and left visible column are set to 1 to reflect the new position. Returns self.
 */
- resetPosition
{
    NXRect pageBounds;

    pageBounds = bounds;
    [self convertRect:&pageBounds toView:[superview superview]];
    [super moveBy: -pageBounds.origin.x + 2.0 :-pageBounds.origin.y + 2.0];
    topVisibleLine = leftVisibleCol = 1;
    return self;
}

/* Calculate the number of lines and columns in the page. We assume that the entire page is of a 
 * single constant-width font. Note that we take the ceiling function of the actual font line height 
 * and width since font heights and widths are expressend in decimals, and the NeXT displays in pixel
 * units (equivalent to integers). For example, the width of a character in Ohlfs 12.0 is 7.2, and the
 * NeXT rounds this value upward to 8.0 when actually displaying. Therefore to get 8.0, we must add 
 * 0.8 or simply take ceil(7.2). As long as the font is a constant width font, the columnsInPage 
 * variable should be accurate, assuming other parameters are changed, such as tactile display columns
 * and lines (see TNTDefinitions.h). Note, we subtract an additional 1.0 since this results in an 
 * accurate columnsInPage value (?). Returns self.
 */
- calcLinesColumns
{
    NXCoord lMgn, rMgn, tMgn, bMgn;

    // lines in page initialization
    [self getMarginLeft:&lMgn right:&rMgn top:&tMgn bottom:&bMgn];
    linesInPage = (frame.size.height - tMgn - bMgn) / [self lineHeight];

    // char width and columns in page initialization
    charWidth = (int)ceil((double)[[self font] getWidthOf:"O"]);
    columnsInPage = (frame.size.width - lMgn - rMgn - 1.0) / charWidth;
    return self;
}

/* Overrides the default -moveBy: method by setting the topVisibleLine and leftVisibleCol in addition
 * to actually moving the page. The topVisibleLine and leftVisibleColumn are then adjusted in case the
 * deltaX and deltaY are to large in either positive or negative amounts. In this way the 
 * topVisibleLine and leftVisibleCol always hold the correct values. If the amount to move the frame
 * rectangle is too large, we move it as much as possible and return nil. Otherwise returns self.
 */
- moveBy:(NXCoord)deltaX :(NXCoord)deltaY
{
    id returnValue = self;

    // move the view as usual
    [super moveBy:-deltaX :-deltaY];

    // set top visible line and adjust
    topVisibleLine += (deltaY / [self lineHeight]);

    if (linesInPage <= TNT_TACTILE_DISPLAY_LINES) {   // all lines of page are visible (special case)
	if (topVisibleLine != 1) {
	    topVisibleLine = 1;
	    returnValue = nil;
	}
    } else if (topVisibleLine > (linesInPage - TNT_TACTILE_DISPLAY_LINES + 1)) {
	topVisibleLine = linesInPage - TNT_TACTILE_DISPLAY_LINES + 1;
	returnValue = nil;
    } else if (topVisibleLine < 1) {
	topVisibleLine = 1;
	returnValue = nil;
    }

    // set left visible column and adjust
    leftVisibleCol += (deltaX / charWidth);

    if (columnsInPage <= TNT_TACTILE_DISPLAY_COLUMNS) {   // all columns of page are visible (special
	if (leftVisibleCol != 1) {                        // case)
	    leftVisibleCol = 1;
	    returnValue = nil;
	}
    } else if (leftVisibleCol > (columnsInPage - TNT_TACTILE_DISPLAY_COLUMNS + 1)) {
	leftVisibleCol = columnsInPage - TNT_TACTILE_DISPLAY_COLUMNS + 1;
	returnValue = nil;
    } else if (leftVisibleCol < 1) {
	leftVisibleCol = 1;
	returnValue = nil;
    }
    return returnValue;
}


/* CURSOR RELATED METHODS ***************************************************************************/


/* Update the system cursor. If the system cursor is on the current page, post a timed-entry to blink
 * the system cursor if one has not already been posted. We then draw the system cursor if it is not 
 * already visible. If the system cursor is not on the current page, we remove the timed-entry 
 * associated with blinking the system cursor, if it has not yet been removed. Returns self.
 */
- updateSystemCursor
{
    NXPoint systemCursorLoc;
    NXCoord lMgn, rMgn, tMgn, bMgn;

    // get margin offsets for compositing
    [self getMarginLeft:&lMgn right:&rMgn top:&tMgn bottom:&bMgn];

    if (pageNumber == [masterDocument systemCursorPage]) {
	if (!systemCursorTE) {   // time-entry not posted, so post it 
	    systemCursorTE = DPSAddTimedEntry(TNT_CURSOR_BLINK_RATE, (void *)&blinkSystemCursor, self,
					      NX_RUNMODALTHRESHOLD);
	}
	if (!systemCursorOnScreen) {   // only draw system cursor if it is not visible
	    systemCursorLoc.x = ([masterDocument systemCursorCol] - 1) * charWidth + lMgn + 
		bounds.origin.x;
	    systemCursorLoc.y = ([masterDocument systemCursorLine]) * [self lineHeight] + tMgn + 
		bounds.origin.y;
	    [systemCursor composite:NX_SOVER toPoint:&systemCursorLoc];
	}
    } else {   // cursor not on page, remove timed-entry to blink system cursor if it exists
	if (systemCursorTE) {
	    DPSRemoveTimedEntry(systemCursorTE);
	    systemCursorTE = (DPSTimedEntry)0;
	}
    }
    return self;
}

/* Update the mark. If the mark is on the current page, post a timed-entry to blink the mark if one
 * has not already been posted. We then draw the mark if it is not already visible. If the mark is not
 * on the current page, we remove the timed-entry associated with blinking the mark, if it has not yet
 * been removed. Returns self.
 */
- updateMark
{
    NXPoint markLoc;
    NXCoord lMgn, rMgn, tMgn, bMgn;

    // get margin offsets for compositing
    [self getMarginLeft:&lMgn right:&rMgn top:&tMgn bottom:&bMgn];

    if (pageNumber == [masterDocument markPage]) {
	if (!markTE) {   // time-entry not posted, so post it
	    markTE = DPSAddTimedEntry(TNT_CURSOR_BLINK_RATE, (void *)&blinkMark, self, 
				      NX_RUNMODALTHRESHOLD);
	}
	if (!markOnScreen) {   // only draw mark if it is not visible
	    markLoc.x = ([masterDocument markCol] - 1) * charWidth + lMgn + bounds.origin.x;
	    markLoc.y = ([masterDocument markLine]) * [self lineHeight] + tMgn + bounds.origin.y;
	    [mark composite:NX_SOVER toPoint:&markLoc];
	}
    } else {   // mark not on page, remove timed-entry to blink mark if it exists
	if (markTE) {
	    DPSRemoveTimedEntry(markTE);
	    markTE = (DPSTimedEntry)0;
	}
    }
    return self;
}

/* This method overrides the inherited method. It Converts a point on the page (in the page's 
 * coordinate system) to a line and column equivalent. The column and line are adjusted since the 
 * window might not be EXACTLY the correct width or height. Essentially, we only convert to the 
 * calculated column and line if they are entirely visible. Otherwise wise we assign the values of the
 * column and line one less than the calculated values. Returns self.
 */
- convertPoint:(NXPoint *)aPoint toLine:(int *)line col:(int *)col
{
    NXCoord lMgn, rMgn, tMgn, bMgn;

    [self getMarginLeft:&lMgn right:&rMgn top:&tMgn bottom:&bMgn];
    *line = (aPoint->y - bounds.origin.y - tMgn) / [self lineHeight] + 1;
    *col = (aPoint->x - bounds.origin.x - lMgn) / charWidth + 1;

    // adjust column for boundary cases
    if (*col < 1) {
	*col = 1;
    } else if (*col > columnsInPage) {
	*col = columnsInPage;
    } else if (*col >= TNT_TACTILE_DISPLAY_COLUMNS + leftVisibleCol) {
	*col = TNT_TACTILE_DISPLAY_COLUMNS + leftVisibleCol - 1;
    }

    // adjust line for boundary cases
    if (*line < 1) {
	*line = 1;
    } else if (*line > linesInPage) {
	*line = linesInPage;
    } else if (*line >= TNT_TACTILE_DISPLAY_LINES + topVisibleLine) {
	*line = TNT_TACTILE_DISPLAY_LINES + topVisibleLine - 1;
    }
    return self;
}

/* The following start/stop cursor blink methods, start cursor blinking ONLY if the cursor is not 
 * already blinking and the cursor is on the current page, and stop cursor blinking ONLY if the cursor
 * already is blinking. These methods are for external use, for when an object wishes to temporarily 
 * stop cursor blinking. All methods return self.
 */

- startSystemCursorBlink
{
    if (pageNumber == [masterDocument systemCursorPage] && !systemCursorTE) {
	// time-entry not posted, so post it 
	systemCursorTE = DPSAddTimedEntry(TNT_CURSOR_BLINK_RATE, (void *)&blinkSystemCursor, self,
					  NX_RUNMODALTHRESHOLD);
    }
    return self;
}

- stopSystemCursorBlink
{
    if (systemCursorTE) {
	DPSRemoveTimedEntry(systemCursorTE);
	systemCursorTE = (DPSTimedEntry)0;
    }
    return self;
}

- startMarkBlink
{
    if (pageNumber == [masterDocument markPage] && !markTE) {   // time-entry not posted, so post it
	markTE = DPSAddTimedEntry(TNT_CURSOR_BLINK_RATE, (void *)&blinkMark, self, 
				  NX_RUNMODALTHRESHOLD);
    }
    return self;
}

- stopMarkBlink
{
    if (markTE) {
	DPSRemoveTimedEntry(markTE);
	markTE = (DPSTimedEntry)0;
    }
    return self;
}


/* DRAWING METHODS **********************************************************************************/


/* Draws a white column one pixel wide at the leftmost and rightmost edges of the page to cover any 
 * protruding characters. We convert a point at (2.0,0.0) from our superview's superview's coordinated
 * system (normally a scroll view) to our coordinate system. This is just for aesthetics when 
 * performing horizontal scrolling. We also draw the system cursor and mark here, depending on whether
 * or not they are in the current page. We query the masterDocument for information on the location of
 * these cursors. Returns self.
 */
- drawSelf:(const NXRect *)rects :(int)rectCount
{
    NXPoint origin = {2.0, 0.0};

    [super drawSelf:rects :rectCount];
    [self convertPoint:&origin fromView:[superview superview]];
    PSsetgray(1.0);
    PSrectfill(origin.x, origin.y, 1.0, bounds.size.height);
    PSrectfill(origin.x + TNT_TACTILE_DISPLAY_WIDTH - 5.0, origin.y, 1.0, bounds.size.height);

    // We set the cursors on screen value to YES, so that the next update call (for each cursor) will
    // erase the cursor (simulating a "blink"). We want to force this since if the cursors are visible
    // when the view is being drawn, then we get flicker. This is especially evident if the view is 
    // being scrolled.

    systemCursorOnScreen = YES;
    markOnScreen = YES;
    [self updateSystemCursor];
    [self updateMark];
    return self;
}


/* SET METHODS **************************************************************************************/


/* This method sets the master document which we contain a portion of, in terms of text. This method 
 * MUST be called in order to draw the cursors on the display, since we message the master document 
 * for cursor locations. Returns self.
 */
- setMasterDocument:aDoc
{
    masterDocument = aDoc;
    return self;
}

- setLeftVisibleCol:(int)col
{
    leftVisibleCol = col;
    return self;
}

- setTopVisibleLine:(int)line
{
    topVisibleLine = line;
    return self;
}

- setPageNumber:(int)number
{
    pageNumber = number;
    return self;
}

- setPageNode:node
{
    pageNode = node;
    return self;
}

- setSystemCursorOnScreen:(BOOL)flag
{
    systemCursorOnScreen = flag;
    return self;
}

- setMarkOnScreen:(BOOL)flag
{
    markOnScreen = flag;
    return self;
}


/* QUERY METHODS ************************************************************************************/


- (int)leftVisibleCol
{
    return leftVisibleCol;
}

- (int)topVisibleLine
{
    return topVisibleLine;
}

- (int)pageNumber
{
    return pageNumber;
}

- pageNode
{
    return pageNode;
}

- (int)linesInPage
{
    return linesInPage;
}

- (int)columnsInPage
{
    return columnsInPage;
}

- (DPSTimedEntry)systemCursorTE
{
    return systemCursorTE;
}

- (DPSTimedEntry)markTE
{
    return markTE;
}

- (BOOL)systemCursorOnScreen
{
    return systemCursorOnScreen;
}

- (BOOL)markOnScreen
{
    return markOnScreen;
}

@end
