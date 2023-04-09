/*
 *    Filename:	TNTServer.m 
 *    Created :	Tue May 18 17:39:59 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Tue Jul 26 11:06:34 1994"
 *
 * $Id: TNTServer.m,v 1.14 1994/07/26 20:11:02 dale Exp $
 *
 * $Log: TNTServer.m,v $
 * Revision 1.14  1994/07/26  20:11:02  dale
 * *** empty log message ***
 *
 * Revision 1.13  1994/06/29  22:39:07  dale
 * Fixed problem with incorrect line/column when dragging in tactile display and the display has been
 * scolled. Modified the scrolling methods to take into account the current top visible line and left
 * visible column.
 *
 * Revision 1.12  1994/06/15  19:32:35  dale
 * Fixed minor bug where last page in page and bookmark locator cannot be accessed.
 *
 * Revision 1.11  1994/06/10  20:18:28  dale
 * *** empty log message ***
 *
 * Revision 1.10  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.9  1994/06/03  08:03:28  dale
 * *** empty log message ***
 *
 * Revision 1.8  1994/06/01  19:13:28  dale
 * Added some fire wall code to deal with locking focuses and views.
 *
 * Revision 1.7  1994/05/28  21:24:37  dale
 * Added page turn methods.
 *
 * Revision 1.6  1993/10/10  20:58:14  dale
 * Added methods to handle manipulation of soft function and left holo sliders.
 *
 * Revision 1.5  1993/08/24  02:08:33  dale
 * *** empty log message ***
 *
 * Revision 1.4  1993/06/11  08:38:39  dale
 * Incorporated GroovePalette for soft function activation.
 *
 * Revision 1.3  1993/06/03  00:37:58  dale
 * *** empty log message ***
 *
 * Revision 1.2  1993/05/27  00:16:28  dale
 * Added various initialization methods.
 *
 * Revision 1.1  1993/05/20  06:03:35  dale
 * Initial revision
 *
 */

#import <grooveslider/GrooveSlider.h>
#import "Publisher.tproj.h"
#import "TactileDisplay.h"
#import "SIL.h"
#import "TNTServer.h"

/* Assign reasonable priority. */
#define PRIORITY 16

@implementation TNTServer

/* Designated initializer for the class. Register's root as root object which receives all messages.
 * Registers serverName with the network name server. This DO interface gives possible future support
 * for TouchNTalk to be run remotely. Returns self.
 */
- initRegisterRoot:root withName:(const char *)serverName;
{
    [super init];
    [[NXConnection registerRoot:root withName:serverName] runFromAppKitWithPriority:PRIORITY];
    return self;
}

/* Register's root as the root object which receives all messages. The default server name of 
 * TNT_SERVER_NAME is registered with the network name server. Returns self.
 */
- initRegisterRoot:root
{
    return [self initRegisterRoot:root withName:TNT_SERVER_NAME];
}

/* Register's the default self as the root object which will receive all messages. The default server
 * name of TNT_SERVER_NAME is registered with the network name server. Returns self.
 */
- init
{
    return [self initRegisterRoot:self withName:TNT_SERVER_NAME];
}

- free
{
    return [super free];
}


/* SET METHODS **************************************************************************************/


/* Here we have all the set... methods which are called from an instance of the TNTControl in order to
 * update the control outlets to point to those in the currently active window. Thus messages sent to
 * the TouchNTalk Server will result in the correct controls being messaged. All return self.
 */

- setPrevPageButton:aButton
{
    prevPageButton = aButton;
    return self;
}

- setNextPageButton:aButton
{
    nextPageButton = aButton;
    return self;
}

- setLeftHolo1Slider:aSlider
{
    leftHolo1Slider = aSlider;
    return self;
}

- setLeftHolo2Slider:aSlider;
{
    leftHolo2Slider = aSlider;
    return self;
}

- setLeftHolo3Slider:aSlider
{
    leftHolo3Slider = aSlider;
    return self;
}

- setLeftHolo4Slider:aSlider
{
    leftHolo4Slider = aSlider;
    return self;
}

- setSoftFunctionSlider:aSlider
{
    softFunctionSlider = aSlider;
    return self;
}

- setPageLocatorSlider:aSlider
{
    pageLocatorSlider = aSlider;
    return self;
}

- setBookmarkHoloSlider:aSlider
{
    bookmarkHoloSlider = aSlider;
    return self;
}

- setHorizPageScrollSlider:aSlider
{
    horizPageScrollSlider = aSlider;
    return self;
}

- setVertPageScrollSlider:aSlider
{
    vertPageScrollSlider = aSlider;
    return self;
}

- setCursorLocatorSlider:aSlider
{
    cursorLocatorSlider = aSlider;
    return self;
}

- setTactileDisplay:aView
{
    tactileDisplay = aView;
    return self;
}

- setSil:aView
{
    sil = aView;
    return self;
}


/* TITLE QUERY METHODS ******************************************************************************/


- holoSetTitle
{
    return holoSetTitle;
}

- speechModeTitle
{
    return speechModeTitle;
}


/* SERVER ACCESS METHODS ****************************************************************************/


- softFunctionDownAt:(float)fraction;
{
    [softFunctionSlider setFloatValue:TNT_SOFTAREA_PARTS * fraction];
    [softFunctionSlider showKnob];
    [[softFunctionSlider mouseDownTarget] perform:[softFunctionSlider mouseDownAction] 
					  with:softFunctionSlider];
    return self;
}

- softFunctionSingleClickAt:(float)fraction;
{
    [softFunctionSlider setFloatValue:TNT_SOFTAREA_PARTS * fraction];
    [[softFunctionSlider singleClickTarget] perform:[softFunctionSlider singleClickAction] 
					    with:softFunctionSlider];
    return self;
}

- softFunctionUpAt:(float)fraction;
{
    [softFunctionSlider setFloatValue:TNT_SOFTAREA_PARTS * fraction];
    [softFunctionSlider hideKnob];    
    [[softFunctionSlider mouseUpTarget] perform:[softFunctionSlider mouseUpAction] 
					with:softFunctionSlider];
    return self;
}

- softFunctionDragTo:(float)fraction
{
    [softFunctionSlider setFloatValue:TNT_SOFTAREA_PARTS * fraction];
    [[softFunctionSlider target] perform:[softFunctionSlider action] 
				 with:softFunctionSlider];
    return self;
}

- leftHolo:(int)holo downAt:(float)fraction
{
    id leftHoloSlider;

    switch (holo) {
      case TNT_LEFTHOLO1:
	leftHoloSlider = leftHolo1Slider;
	break;
      case TNT_LEFTHOLO2:
	leftHoloSlider = leftHolo2Slider;
	break;
      case TNT_LEFTHOLO3:
	leftHoloSlider = leftHolo3Slider;
	break;
      case TNT_LEFTHOLO4:
	leftHoloSlider = leftHolo4Slider;
	break;	
      default:
	leftHoloSlider = nil;
	break;
    }
    [leftHoloSlider setFloatValue:TNT_LEFTHOLO_PARTS * fraction];
    [leftHoloSlider showKnob];
    [[leftHoloSlider mouseDownTarget] perform:[leftHoloSlider mouseDownAction] 
				      with:leftHoloSlider];
    return self;
}

- leftHolo:(int)holo singleClickAt:(float)fraction
{
    id leftHoloSlider;

    switch (holo) {
      case TNT_LEFTHOLO1:
	leftHoloSlider = leftHolo1Slider;
	break;
      case TNT_LEFTHOLO2:
	leftHoloSlider = leftHolo2Slider;
	break;
      case TNT_LEFTHOLO3:
	leftHoloSlider = leftHolo3Slider;
	break;
      case TNT_LEFTHOLO4:
	leftHoloSlider = leftHolo4Slider;
	break;	
      default:
	leftHoloSlider = nil;
	break;
    }
    [leftHoloSlider setFloatValue:TNT_LEFTHOLO_PARTS * fraction];
    [[leftHoloSlider singleClickTarget] perform:[leftHoloSlider singleClickAction] 
					with:leftHoloSlider];
    return self;
}

- leftHolo:(int)holo doubleClickAt:(float)fraction
{
    id leftHoloSlider;

    switch (holo) {
      case TNT_LEFTHOLO1:
	leftHoloSlider = leftHolo1Slider;
	break;
      case TNT_LEFTHOLO2:
	leftHoloSlider = leftHolo2Slider;
	break;
      case TNT_LEFTHOLO3:
	leftHoloSlider = leftHolo3Slider;
	break;
      case TNT_LEFTHOLO4:
	leftHoloSlider = leftHolo4Slider;
	break;	
      default:
	leftHoloSlider = nil;
	break;
    }
    [leftHoloSlider setFloatValue:TNT_LEFTHOLO_PARTS * fraction];
    [[leftHoloSlider doubleClickTarget] perform:[leftHoloSlider doubleClickAction] 
					with:leftHoloSlider];
    return self;
}

- leftHolo:(int)holo upAt:(float)fraction
{
    id leftHoloSlider;

    switch (holo) {
      case TNT_LEFTHOLO1:
	leftHoloSlider = leftHolo1Slider;
	break;
      case TNT_LEFTHOLO2:
	leftHoloSlider = leftHolo2Slider;
	break;
      case TNT_LEFTHOLO3:
	leftHoloSlider = leftHolo3Slider;
	break;
      case TNT_LEFTHOLO4:
	leftHoloSlider = leftHolo4Slider;
	break;	
      default:
	leftHoloSlider = nil;
	break;
    }
    [leftHoloSlider setFloatValue:TNT_LEFTHOLO_PARTS * fraction];
    [leftHoloSlider hideKnob];    
    [[leftHoloSlider mouseUpTarget] perform:[leftHoloSlider mouseUpAction] 
				    with:leftHoloSlider];
    return self;
}

- leftHolo:(int)holo dragTo:(float)fraction
{
    id leftHoloSlider;

    switch (holo) {
      case TNT_LEFTHOLO1:
	leftHoloSlider = leftHolo1Slider;
	break;
      case TNT_LEFTHOLO2:
	leftHoloSlider = leftHolo2Slider;
	break;
      case TNT_LEFTHOLO3:
	leftHoloSlider = leftHolo3Slider;
	break;
      case TNT_LEFTHOLO4:
	leftHoloSlider = leftHolo4Slider;
	break;	
      default:
	leftHoloSlider = nil;
	break;
    }
    [leftHoloSlider setFloatValue:TNT_LEFTHOLO_PARTS * fraction];
    [[leftHoloSlider target] perform:[leftHoloSlider action] 
			     with:leftHoloSlider];
    return self;
}

- pageLocatorDownAt:(float)fraction
{
    [pageLocatorSlider setFloatValue:([[tactileDisplay document] pages] + 1) * fraction];
    [pageLocatorSlider showKnob];
    [[pageLocatorSlider mouseDownTarget] perform:[pageLocatorSlider mouseDownAction] 
					 with:pageLocatorSlider];
    return self;
}

- pageLocatorSingleClickAt:(float)fraction
{
    [pageLocatorSlider setFloatValue:([[tactileDisplay document] pages] + 1) * fraction];
    [[pageLocatorSlider singleClickTarget] perform:[pageLocatorSlider singleClickAction] 
					   with:pageLocatorSlider];
    return self;
}

- pageLocatorDoubleClickAt:(float)fraction
{
    [pageLocatorSlider setFloatValue:([[tactileDisplay document] pages] + 1) * fraction];
    [[pageLocatorSlider doubleClickTarget] perform:[pageLocatorSlider doubleClickAction] 
					   with:pageLocatorSlider];
    return self;
}

- pageLocatorUpAt:(float)fraction
{
    [pageLocatorSlider setFloatValue:([[tactileDisplay document] pages] + 1) * fraction];
    [pageLocatorSlider hideKnob];    
    [[pageLocatorSlider mouseUpTarget] perform:[pageLocatorSlider mouseUpAction] 
				       with:pageLocatorSlider];
    return self;
}

- pageLocatorDragTo:(float)fraction
{
    [pageLocatorSlider setFloatValue:([[tactileDisplay document] pages] + 1) * fraction];
    [[pageLocatorSlider target] perform:[pageLocatorSlider action] 
				with:pageLocatorSlider];
    return self;
}

- bookmarkLocatorDownAt:(float)fraction
{
    [bookmarkHoloSlider setFloatValue:([[tactileDisplay document] pages] + 1) * fraction];
    [bookmarkHoloSlider showKnob];
    [[bookmarkHoloSlider mouseDownTarget] perform:[bookmarkHoloSlider mouseDownAction] 
					  with:bookmarkHoloSlider];
    return self;
}

- bookmarkLocatorSingleClickAt:(float)fraction
{
    [bookmarkHoloSlider setFloatValue:([[tactileDisplay document] pages] + 1) * fraction];
    [[bookmarkHoloSlider singleClickTarget] perform:[bookmarkHoloSlider singleClickAction] 
					    with:bookmarkHoloSlider];
    return self;
}

- bookmarkLocatorDoubleClickAt:(float)fraction
{
    [bookmarkHoloSlider setFloatValue:([[tactileDisplay document] pages] + 1) * fraction];
    [[bookmarkHoloSlider doubleClickTarget] perform:[bookmarkHoloSlider doubleClickAction] 
					    with:bookmarkHoloSlider];
    return self;
}

- bookmarkLocatorUpAt:(float)fraction
{
    [bookmarkHoloSlider setFloatValue:([[tactileDisplay document] pages] + 1) * fraction];
    [bookmarkHoloSlider hideKnob];    
    [[bookmarkHoloSlider mouseUpTarget] perform:[bookmarkHoloSlider mouseUpAction] 
					with:bookmarkHoloSlider];
    return self;
}

- bookmarkLocatorDragTo:(float)fraction
{
    [bookmarkHoloSlider setFloatValue:([[tactileDisplay document] pages] + 1) * fraction];
    [[bookmarkHoloSlider target] perform:[bookmarkHoloSlider action] 
				 with:bookmarkHoloSlider];
    return self;
}

- horizPageScrollDownAt:(float)fraction
{
    [horizPageScrollSlider setFloatValue:TNT_HORIZ_PAGESCROLL_PARTS * fraction];
    [horizPageScrollSlider showKnob];
    [[horizPageScrollSlider mouseDownTarget] perform:[horizPageScrollSlider mouseDownAction] 
					     with:horizPageScrollSlider];
    return self;
}

/* Currently never invoked. */
- horizPageScrollSingleClickAt:(float)fraction
{
    [horizPageScrollSlider setFloatValue:TNT_HORIZ_PAGESCROLL_PARTS * fraction];
    [[horizPageScrollSlider mouseUpTarget] perform:[horizPageScrollSlider mouseUpAction] 
					   with:horizPageScrollSlider];
    return self;
}

- horizPageScrollUpAt:(float)fraction
{
    [horizPageScrollSlider setFloatValue:TNT_HORIZ_PAGESCROLL_PARTS * fraction];
    [horizPageScrollSlider hideKnob];    
    [[horizPageScrollSlider mouseUpTarget] perform:[horizPageScrollSlider mouseUpAction] 
					   with:horizPageScrollSlider];
    return self;
}

- horizPageScrollDragTo:(float)fraction
{
    [horizPageScrollSlider setFloatValue:TNT_HORIZ_PAGESCROLL_PARTS * fraction];
    [[horizPageScrollSlider target] perform:[horizPageScrollSlider action] 
				    with:horizPageScrollSlider];
    return self;
}

- cursorLocatorDownAt:(float)fraction
{
    [cursorLocatorSlider setFloatValue:TNT_RIGHTAREA_PARTS * fraction];
    [cursorLocatorSlider showKnob];
    [[cursorLocatorSlider mouseDownTarget] perform:[cursorLocatorSlider mouseDownAction] 
					   with:cursorLocatorSlider];
    return self;
}

- cursorLocatorSingleClickAt:(float)fraction
{
    [cursorLocatorSlider setFloatValue:TNT_RIGHTAREA_PARTS * fraction];
    [[cursorLocatorSlider singleClickTarget] perform:[cursorLocatorSlider singleClickAction] 
					     with:cursorLocatorSlider];
    return self;
}

- cursorLocatorDoubleClickAt:(float)fraction
{
    [cursorLocatorSlider setFloatValue:TNT_RIGHTAREA_PARTS * fraction];
    [[cursorLocatorSlider doubleClickTarget] perform:[cursorLocatorSlider doubleClickAction] 
					     with:cursorLocatorSlider];
    return self;
}

- cursorLocatorUpAt:(float)fraction
{
    [cursorLocatorSlider setFloatValue:TNT_RIGHTAREA_PARTS * fraction];
    [cursorLocatorSlider hideKnob];    
    [[cursorLocatorSlider mouseUpTarget] perform:[cursorLocatorSlider mouseUpAction] 
					 with:cursorLocatorSlider];
    return self;
}

- cursorLocatorDragTo:(float)fraction
{
    [cursorLocatorSlider setFloatValue:TNT_RIGHTAREA_PARTS * fraction];
    [[cursorLocatorSlider target] perform:[cursorLocatorSlider action] 
				  with:cursorLocatorSlider];
    return self;
}

- vertPageScrollDownAt:(float)fraction
{
    [vertPageScrollSlider setFloatValue:TNT_RIGHTAREA_PARTS * fraction];
    [vertPageScrollSlider showKnob];
    [[vertPageScrollSlider mouseDownTarget] perform:[vertPageScrollSlider mouseDownAction] 
					    with:vertPageScrollSlider];
    return self;
}

/* Currently never invoked. */
- vertPageScrollSingleClickAt:(float)fraction
{
    [vertPageScrollSlider setFloatValue:TNT_RIGHTAREA_PARTS * fraction];
    [[vertPageScrollSlider singleClickTarget] perform:[vertPageScrollSlider singleClickAction] 
					      with:vertPageScrollSlider];
    return self;
}

- vertPageScrollUpAt:(float)fraction
{
    [vertPageScrollSlider setFloatValue:TNT_RIGHTAREA_PARTS * fraction];
    [vertPageScrollSlider hideKnob];    
    [[vertPageScrollSlider mouseUpTarget] perform:[vertPageScrollSlider mouseUpAction] 
					  with:vertPageScrollSlider];
    return self;
}


- vertPageScrollDragTo:(float)fraction
{
    [vertPageScrollSlider setFloatValue:TNT_RIGHTAREA_PARTS * fraction];
    [[vertPageScrollSlider target] perform:[vertPageScrollSlider action] 
				   with:vertPageScrollSlider];
    return self;
}

/* Note, we must offset the user both vertically and horizontally based on the top visible line and
 * left visible column of the display.
 */
- tactileGroove:(int)groove downAt:(float)fraction
{
    id activePage = [tactileDisplay activePage];

    if ([NXApp focusView])
	[[NXApp focusView] unlockFocus];
    [activePage lockFocus];
    PSsetinstance(YES);         // turn on instance drawing

    [activePage setUserCursorOnScreen:YES];
    [activePage showUserCursorAt:groove + [activePage topVisibleLine] - 1
		:(int)floor(TNT_TACTILE_DISPLAY_COLUMNS * fraction + 1) +
		([activePage leftVisibleCol] - 1)];
    [[activePage mouseDownTarget] perform:[activePage mouseDownAction] with:activePage];
    return self;
}

- tactileGroove:(int)groove singleClickAt:(float)fraction
{
    id activePage = [tactileDisplay activePage];

    [[activePage singleClickTarget] perform:[activePage singleClickAction] with:activePage];
    return self;
}

- tactileGroove:(int)groove doubleClickAt:(float)fraction
{
    id activePage = [tactileDisplay activePage];

    [[activePage doubleClickTarget] perform:[activePage doubleClickAction] with:activePage];
    return self;
}

- tactileGroove:(int)groove upAt:(float)fraction
{
    id activePage = [tactileDisplay activePage];

    [activePage setUserCursorOnScreen:NO];   // user cursor should no longer appear on screen
    PSnewinstance();                         // erase instance drawing so user cursor disappears
    PSsetinstance(NO);                       // turn off instance drawing
    if ([activePage isFocusView])
	[activePage unlockFocus];
    [[activePage mouseUpTarget] perform:[activePage mouseUpAction] with:activePage];
    return self;
}

/* Note, we must offset the user both vertically and horizontally based on the top visible line and
 * left visible column of the display.
 */
- tactileGroove:(int)groove dragTo:(float)fraction
{
    id activePage = [tactileDisplay activePage];

    PSnewinstance();   // erase all instance drawing, so previous user cursor disappears
    [activePage showUserCursorAt:groove + [activePage topVisibleLine] - 1
		:(int)floor(TNT_TACTILE_DISPLAY_COLUMNS * fraction + 1) +
		([activePage leftVisibleCol] - 1)];
    [[activePage mouseDragTarget] perform:[activePage mouseDragAction] with:activePage];
    return self;
}

- silDownAt:(float)fraction
{
    id silText = [sil silText];

    // set up drawing context and draw user cursor
    if ([NXApp focusView])
	[[NXApp focusView] unlockFocus];
    [silText lockFocus];
    PSsetinstance(YES);         // turn on instance drawing

    [silText setUserCursorOnScreen:YES];
    [silText showUserCursorAt:1 :(int)floor(TNT_TACTILE_DISPLAY_COLUMNS * fraction + 1)];
    [[silText mouseDownTarget] perform:[silText mouseDownAction] with:silText];
    return self;
}

- silSingleClickAt:(float)fraction
{
    id silText = [sil silText];

    [silText showUserCursorAt:1 :(int)floor(TNT_TACTILE_DISPLAY_COLUMNS * fraction + 1)];
    [[silText singleClickTarget] perform:[silText singleClickAction] with:silText];
    return self;
}

- silDoubleClickAt:(float)fraction
{
    id silText = [sil silText];

    [silText showUserCursorAt:1 :(int)floor(TNT_TACTILE_DISPLAY_COLUMNS * fraction + 1)];
    [[silText doubleClickTarget] perform:[silText doubleClickAction] with:silText];
    return self;
}

- silUpAt:(float)fraction
{
    id silText = [sil silText];

    [silText setUserCursorOnScreen:NO];   // user cursor should no longer appear on screen
    PSnewinstance();                      // erase instance drawing so user cursor disappears
    PSsetinstance(NO);                    // turn off instance drawing
    if ([silText isFocusView])
	[silText unlockFocus];
    [[silText mouseUpTarget] perform:[silText mouseUpAction] with:silText];
    return self;
}

- silDragTo:(float)fraction
{
    id silText = [sil silText];

    PSnewinstance();   // erase all instance drawing, so previous user cursor disappears
    [silText showUserCursorAt:1 :(int)floor(TNT_TACTILE_DISPLAY_COLUMNS * fraction + 1)];
    [[silText mouseDragTarget] perform:[silText mouseDragAction] with:silText];
    return self;
}

/* These two page turning methods turn to the appropriate page of the document based on the number of
 * clicks. If we cannot turn the full page count due to encountering the end of the document, we
 * turn as many pages as we can, and beep to indicate the end of the document has been encountered.
 * 
 * NOTE: When consecutive pages with greater than TNT_TACTILE_DISPLAY_COLUMNS columns occur, the view
 * is not updated properly if horizontally scrolled, so we must always send the -display message to 
 * the view to circumvent this problem. The -display message is also required to update the system 
 * cursor and mark if necessary.
 */

- pageNextClicks:(int)numClicks
{
    id document = [tactileDisplay document];
    id window = [tactileDisplay window];

    [window disableFlushWindow];
    if (![[tactileDisplay document] setRelativeActivePage:numClicks])
	NXBeep();
    [window reenableFlushWindow];
    [[tactileDisplay activePage] display];
    sprintf(buffer, "Page %d of %d.", [document activePageNumber], [document pages]);
    [sil setText:buffer];
    return self;
}

- pagePreviousClicks:(int)numClicks
{
    id document = [tactileDisplay document];
    id window = [tactileDisplay window];

    [window disableFlushWindow];
    if (![[tactileDisplay document] setRelativeActivePage:-numClicks])
	NXBeep();
    [window reenableFlushWindow];
    [[tactileDisplay activePage] display];
    sprintf(buffer, "Page %d of %d.", [document activePageNumber], [document pages]);
    [sil setText:buffer];
    return self;
}

@end
