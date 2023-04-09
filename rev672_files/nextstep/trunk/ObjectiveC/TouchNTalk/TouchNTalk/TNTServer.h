/*
 *    Filename:	TNTServer.h 
 *    Created :	Wed May 19 14:38:58 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Mon Jun 27 14:19:55 1994"
 *
 * $Id: TNTServer.h,v 1.14 1994/06/29 22:39:07 dale Exp $
 *
 * $Log: TNTServer.h,v $
 * Revision 1.14  1994/06/29  22:39:07  dale
 * Fixed problem with incorrect line/column when dragging in tactile display and the display has been
 * scolled. Modified the scrolling methods to take into account the current top visible line and left
 * visible column.
 *
 * Revision 1.13  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.12  1994/06/01  19:13:28  dale
 * Added some fire wall code to deal with locking focuses and views.
 *
 * Revision 1.11  1994/05/28  21:24:37  dale
 * Added page turn methods.
 *
 * Revision 1.10  1993/10/10  20:58:14  dale
 * Added methods to handle manipulation of soft function and left holo sliders.
 *
 * Revision 1.9  1993/08/24  02:08:33  dale
 * *** empty log message ***
 *
 * Revision 1.8  1993/07/23  07:33:00  dale
 * *** empty log message ***
 *
 * Revision 1.7  1993/06/18  08:45:44  dale
 * *** empty log message ***
 *
 * Revision 1.6  1993/06/16  07:45:38  dale
 * *** empty log message ***
 *
 * Revision 1.5  1993/06/04  20:57:48  dale
 * *** empty log message ***
 *
 * Revision 1.4  1993/06/03  00:37:58  dale
 * *** empty log message ***
 *
 * Revision 1.3  1993/05/30  08:24:27  dale
 * *** empty log message ***
 *
 * Revision 1.2  1993/05/27  00:16:28  dale
 * Added title instance variables to reflect interface changes.
 *
 * Revision 1.1  1993/05/20  06:03:35  dale
 * Initial revision
 *
 */

#import <appkit/appkit.h>

@interface TNTServer:Object
{
    // IB outlets
    id helpTitle;
    id openTitle;
    id saveTitle;
    id closeTitle;
    id pageTitle;
    id shellTitle;
    id windowsTitle;
    id holoSetTitle;
    id speechModeTitle;
    id configureTitle;
    id softTitleMatrix;

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

    id tactileDisplay;
    id sil;

    char buffer[MAXPATHLEN+128];   // utility buffer (SIL, file paths, etc.)
}

/* INITIALIZING AND FREEING */
- initRegisterRoot:root withName:(const char *)serverName;
- initRegisterRoot:root;
- init;
- free;

/* OUTLET SETTING */
- setPrevPageButton:aButton;
- setNextPageButton:aButton;

- setLeftHolo1Slider:aSlider;
- setLeftHolo2Slider:aSlider;
- setLeftHolo3Slider:aSlider;
- setLeftHolo4Slider:aSlider;

- setPageLocatorSlider:aSlider;
- setBookmarkHoloSlider:aSlider;
- setHorizPageScrollSlider:aSlider;
- setVertPageScrollSlider:aSlider;
- setCursorLocatorSlider:aSlider;

- setTactileDisplay:aView;
- setSil:aView;

/* TITLE QUERY METHODS */
- holoSetTitle;
- speechModeTitle;

/* SERVER ACCESS METHODS */
- softFunctionDownAt:(float)fraction;
- softFunctionSingleClickAt:(float)fraction;
- softFunctionUpAt:(float)fraction;
- softFunctionDragTo:(float)fraction;

- leftHolo:(int)holo downAt:(float)fraction;
- leftHolo:(int)holo singleClickAt:(float)fraction;
- leftHolo:(int)holo doubleClickAt:(float)fraction;
- leftHolo:(int)holo upAt:(float)fraction;
- leftHolo:(int)holo dragTo:(float)fraction;

- pageLocatorDownAt:(float)fraction;
- pageLocatorSingleClickAt:(float)fraction;
- pageLocatorDoubleClickAt:(float)fraction;
- pageLocatorUpAt:(float)fraction;
- pageLocatorDragTo:(float)fraction;

- bookmarkLocatorDownAt:(float)fraction;
- bookmarkLocatorSingleClickAt:(float)fraction;
- bookmarkLocatorDoubleClickAt:(float)fraction;
- bookmarkLocatorUpAt:(float)fraction;
- bookmarkLocatorDragTo:(float)fraction;

- horizPageScrollDownAt:(float)fraction;
- horizPageScrollSingleClickAt:(float)fraction;
- horizPageScrollUpAt:(float)fraction;
- horizPageScrollDragTo:(float)fraction;

- cursorLocatorDownAt:(float)fraction;
- cursorLocatorSingleClickAt:(float)fraction;
- cursorLocatorDoubleClickAt:(float)fraction;
- cursorLocatorUpAt:(float)fraction;
- cursorLocatorDragTo:(float)fraction;

- vertPageScrollDownAt:(float)fraction;
- vertPageScrollSingleClickAt:(float)fraction;
- vertPageScrollUpAt:(float)fraction;
- vertPageScrollDragTo:(float)fraction;

- tactileGroove:(int)groove downAt:(float)fraction;
- tactileGroove:(int)groove singleClickAt:(float)fraction;
- tactileGroove:(int)groove doubleClickAt:(float)fraction;
- tactileGroove:(int)groove upAt:(float)fraction;
- tactileGroove:(int)groove dragTo:(float)fraction;

- silDownAt:(float)fraction;
- silSingleClickAt:(float)fraction;
- silDoubleClickAt:(float)fraction;
- silUpAt:(float)fraction;
- silDragTo:(float)fraction;

- pageNextClicks:(int)numClicks;
- pagePreviousClicks:(int)numClicks;

@end
