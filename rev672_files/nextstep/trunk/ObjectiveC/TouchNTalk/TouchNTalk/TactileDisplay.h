/*
 *    Filename:	TactileDisplay.h 
 *    Created :	Wed May 19 14:39:12 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Wed Jun 29 16:52:52 1994"
 *
 * $Id: TactileDisplay.h,v 1.23 1994/06/29 22:53:11 dale Exp $
 *
 * $Log: TactileDisplay.h,v $
 * Revision 1.23  1994/06/29  22:53:11  dale
 * Added complete cursor location support.
 *
 * Revision 1.22  1994/06/29  22:39:07  dale
 * Fixed inconsistent vertical/horizontal behavioural problem. 
 *
 * Revision 1.21  1994/06/10  20:18:28  dale
 * *** empty log message ***
 *
 * Revision 1.20  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.19  1994/06/03  08:03:28  dale
 * *** empty log message ***
 *
 * Revision 1.18  1994/06/01  19:13:28  dale
 * *** empty log message ***
 *
 * Revision 1.17  1993/08/24  02:08:33  dale
 * *** empty log message ***
 *
 * Revision 1.16  1993/07/23  07:33:00  dale
 * *** empty log message ***
 *
 * Revision 1.15  1993/07/14  22:11:48  dale
 * *** empty log message ***
 *
 * Revision 1.14  1993/07/06  00:34:26  dale
 * *** empty log message ***
 *
 * Revision 1.13  1993/07/01  20:18:47  dale
 * Added bookmark panel for entering bookmarks.
 *
 * Revision 1.12  1993/06/25  23:38:25  dale
 * Completed Page locator, and bookmark holophrast functionality.
 *
 * Revision 1.11  1993/06/24  07:40:50  dale
 * Moved some position setting, and charWidth calculation methods to the Page class.
 *
 * Revision 1.10  1993/06/22  19:50:38  dale
 * Completed scrolling behaviour, and added cursor location, with mouse click to select page with
 * system cursor, centering the page as much as possible so that the system cursor lies in the center
 * of the view.
 *
 * Revision 1.9  1993/06/18  08:45:44  dale
 * Added scrolling behaviour, and fixed left holophrast behaviour.
 *
 * Revision 1.8  1993/06/16  07:45:38  dale
 * Removed interface buttons.
 *
 * Revision 1.7  1993/06/14  15:09:57  dale
 * *** empty log message ***
 *
 * Revision 1.6  1993/06/09  18:23:00  dale
 * Added end node detection with appropriate sound.
 *
 * Revision 1.5  1993/06/07  08:11:40  dale
 * Initial attempt made at getting left holophrasts working throughout the system.
 *
 * Revision 1.4  1993/06/05  07:37:08  dale
 * *** empty log message ***
 *
 * Revision 1.3  1993/05/30  08:24:27  dale
 * *** empty log message ***
 *
 * Revision 1.2  1993/05/27  00:16:28  dale
 * Added action methods to deal with button presses associated with sliders.
 *
 * Revision 1.1  1993/05/20  06:03:35  dale
 * Initial revision
 *
 */

#import <appkit/appkit.h>

@interface TactileDisplay:ScrollView
{
    id tntControl;                 // TNTControl instance for our window
    id document;                   // the actual document (instance of Document)
    id activePage;                 // the active page of the document (instance of Page)
    id tone;                       // instance of Tone class to generate locator tones
    char buffer[MAXPATHLEN+128];   // buffer for sending messages to the SIL

    // shared speaker instances
    id tactileSpeaker;

    // IB outlets for bookmark panel
    id bookmarkPanel;              // IB Outlet
    id instructionsTitle;          // IB Outlet
    id nameField;                  // IB Outlet

    // node sounds
    id startNodeSound;
    id endNodeSound;
    id endSeriesSound;

    // general interface state information
    id lastNodeHighlighted;        // holds the last node that was highlighted
    int lastLine;                  // holds last line for groove sliders (left holo's, cursor locator)
    int lastCol;                   // holds last column for groove sliders (page locator, bookmark)

    // left holophrast state information
    id nodeList;                   // node List for currently active left holophrast
    int nodeIndex;                 // holds index for last node displayed in nodeList
    BOOL topPage;                  // indicates whether node crosses top page boundary
    BOOL bottomPage;               // indicates whether node crosses bottom page boundary

    // vertical/horizontal scroll state information
    id overScrollSound;               // sound when overscrolling
    int startTopLine;                 // topmost visible line at start of scrolling action
    int startLeftCol;                 // leftmost visible column at start of scrolling action
    int currScrollVal;                // current scroll slider value (during scroll action)
    int lastScrollVal;                // last scroll slider value (during scroll action)
    BOOL overScroll;                  // did we finish by overscrolling?

    // interface controls (IB Outlets)
    id prevPageButton;
    id nextPageButton;

    id leftHolo1Slider;
    id leftHolo2Slider;
    id leftHolo3Slider;
    id leftHolo4Slider;

    id softFunctionSlider;
    id pageLocatorSlider;
    id bookmarkHoloSlider;
    id horizPageScrollSlider;
    id vertPageScrollSlider;
    id cursorLocatorSlider;

    id sil;
}

/* INITIALIZING AND FREEING */
- initFrame:(NXRect *)frameRect;
- initTargetAction;
- awakeFromNib;
- free;

/* SET METHODS */
- setDocument:aDoc;

/* QUERY METHODS */
- document;
- activePage;
- bookmarkPanel;
- tone;

/* ACTION METHODS */
- pageBackward:sender;
- pageForward:sender;

- addChangeRemoveBookmark:sender;
- cancelBookmark:sender;

- vertPageScrollDown:sender;
- vertPageScrollActive:sender;
- vertPageScrollUp:sender;

- horizPageScrollDown:sender;
- horizPageScrollActive:sender;
- horizPageScrollUp:sender;

- pageLocatorActive:sender;
- pageLocatorSelect:sender;
- pageLocatorUp:sender;

- bookmarkHoloActive:sender;
- bookmarkHoloSelect:sender;
- bookmarkHoloDoubleSelect:sender;
- bookmarkHoloUp:sender;

- cursorLocatorActive:sender;
- cursorLocatorSelect:sender;
- cursorLocatorDoubleSelect:sender;
- cursorLocatorUp:sender;

- leftHolo1Active:sender;
- leftHolo2Active:sender;
- leftHolo3Active:sender;
- leftHolo4Active:sender;

- leftHoloSelect:sender;
- leftHoloUp:sender;

- leftHolo1Preview:sender;
- leftHolo2Preview:sender;
- leftHolo3Preview:sender;
- leftHolo4Preview:sender;

/* NODE HIGHLIGHT METHODS */
- highlightNodeAt:(int)line inList:holoNodeList;
- highlightNodeAt:(int)index;
- highlightNode:node;
- (BOOL)node:aNode spansLine:(int)line;

/* CURSOR MANIPULATION METHODS */
- repositionCursors;
- swapCursors;
- (BOOL)userCursorAtSystemCursor;

/* UTILITY METHODS */
- playLocatorTone;
- resetDocument;

@end
