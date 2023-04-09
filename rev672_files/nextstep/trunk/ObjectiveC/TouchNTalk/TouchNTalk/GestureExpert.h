/*
 *    Filename:	GestureExpert.h 
 *    Created :	Wed Sep  1 13:03:09 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Tue Jul 26 00:43:30 1994"
 *
 * $Id: GestureExpert.h,v 1.6 1994/07/26 20:11:02 dale Exp $
 *
 * $Log: GestureExpert.h,v $
 * Revision 1.6  1994/07/26  20:11:02  dale
 * *** empty log message ***
 *
 * Revision 1.5  1994/06/29  22:39:07  dale
 * Added column cursor locator support.
 *
 * Revision 1.4  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.3  1994/05/28  21:24:37  dale
 * Added backward and forward page turns.
 *
 * Revision 1.2  1993/10/10  20:58:14  dale
 * Added soft function and left holo "gesture" recognition.
 *
 * Revision 1.1  1993/09/04  17:49:02  dale
 * Initial revision
 *
 */

#import <objc/Object.h>
#import <dpsclient/dpsclient.h>

@interface GestureExpert:Object
{
    id tabletSurface;   // tablet surface instance
    id ttServer;       // TouchNTalk "server" for manipulating graphical controls
}

/* INITIALIZING AND FREEING */
- init;
- free;

/* DISPATCH EVENT */
- pandemonium:(NXEvent *)theEvent;

/* PRIVATE GESTURES */
- softFunctionGesture:(NXEvent *)theEvent;
- leftHoloGesture:(NXEvent *)theEvent;

- pageLocatorGesture:(NXEvent *)theEvent;
- bookmarkLocatorGesture:(NXEvent *)theEvent;
- horizontalScrollGesture:(NXEvent *)theEvent;
- cursorLocatorGesture:(NXEvent *)theEvent;
- verticalScrollGesture:(NXEvent *)theEvent;
- pageNextGesture:(NXEvent *)theEvent;
- pagePrevGesture:(NXEvent *)theEvent;
- tactileAreaGesture:(NXEvent *)theEvent;
- silAreaGesture:(NXEvent *)theEvent;

/* DEBUGGING */
- showContents:(NXEvent *)theEvent;

@end
