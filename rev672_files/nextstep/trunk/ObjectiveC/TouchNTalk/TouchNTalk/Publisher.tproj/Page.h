/*
 *    Filename:	Page.h 
 *    Created :	Thu May 13 12:02:47 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Wed Jun 29 11:42:48 1994"
 *
 * $Id: Page.h,v 1.15 1994/06/29 22:39:07 dale Exp $
 *
 * $Log: Page.h,v $
 * Revision 1.15  1994/06/29  22:39:07  dale
 * Overrided default -moveBy:: to automatically adjust topmost visible line and leftmost visible
 * column, in addition to doing the normal thing. It should no longer be necessary for set... methods
 * for these instance variables to be used.
 *
 * Revision 1.14  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.13  1993/08/27  03:51:06  dale
 * Added methods to start and stop cursor blinking.
 *
 * Revision 1.12  1993/07/23  07:33:00  dale
 * *** empty log message ***
 *
 * Revision 1.11  1993/07/14  22:11:48  dale
 * *** empty log message ***
 *
 * Revision 1.10  1993/07/06  00:34:26  dale
 * Incorporated SpeakTactileText object.
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

#import <appkit/appkit.h>
#import "TactileText.h"

@interface Page:TactileText
{
    int leftVisibleCol;   // leftmost visible column number (1-based)
    int topVisibleLine;   // topmost visible line number (1-based)
    int pageNumber;       // page number of current page (1-based)
    id pageNode;          // instance of Node object containing page information
    id masterDocument;    // handle to the master document which we contain a portion of

    int linesInPage;      // lines in page
    int columnsInPage;    // columns in page

    // NXImage cursors
    id systemCursor;
    id mark;

    // cursor timed-entry tags
    DPSTimedEntry systemCursorTE;
    DPSTimedEntry markTE;    

    // cursor screen status
    BOOL systemCursorOnScreen;
    BOOL markOnScreen;
}

/* INITIALIZING AND FREEING */
- initFrame:(const NXRect *)frameRect text:(const char *)theText alignment:(int)mode;
- initFrame:(const NXRect *)frameRect;
- free;

/* ADJUSTMENT METHODS */
- calcLinesColumns;
- resetPosition;
- moveBy:(NXCoord)deltaX :(NXCoord)deltaY;   // OVERIDDEN

/* CURSOR RELATED METHODS */
- convertPoint:(NXPoint *)aPoint toLine:(int *)line col:(int *)col;
- updateSystemCursor;
- updateMark;
- startSystemCursorBlink;
- stopSystemCursorBlink;
- startMarkBlink;
- stopMarkBlink;

/* DRAWING METHODS */
- drawSelf:(const NXRect *)rects :(int)rectCount;

/* SET METHODS */
- setMasterDocument:aDoc;
- setLeftVisibleCol:(int)col;
- setTopVisibleLine:(int)line;
- setPageNumber:(int)number;
- setPageNode:node;

- setSystemCursorOnScreen:(BOOL)flag;
- setMarkOnScreen:(BOOL)flag;

/* QUERY METHODS */
- (int)leftVisibleCol;
- (int)topVisibleLine;
- (int)pageNumber;
- pageNode;

- (int)linesInPage;
- (int)columnsInPage;

- (DPSTimedEntry)systemCursorTE;
- (DPSTimedEntry)markTE;

- (BOOL)systemCursorOnScreen;
- (BOOL)markOnScreen;

@end
