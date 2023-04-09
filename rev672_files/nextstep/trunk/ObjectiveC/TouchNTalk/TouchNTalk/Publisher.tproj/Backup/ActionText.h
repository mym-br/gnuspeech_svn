/*
 *    Filename:	ActionText.h 
 *    Created :	Sun Jul 11 12:17:36 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Fri Jul 23 12:44:48 1993"
 *
 * $Id: ActionText.h,v 1.4 1994/06/03 19:28:24 dale Exp $
 *
 * $Log: ActionText.h,v $
 * Revision 1.4  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.3  1993/08/24  02:08:33  dale
 * *** empty log message ***
 *
 * Revision 1.2  1993/07/23  07:32:18  dale
 * *** empty log message ***
 *
 * Revision 1.1  1993/07/14  22:11:48  dale
 * Initial revision
 *
 */

#import <appkit/appkit.h>
#import <drivers/event_status_driver.h>
#import "SpeakText.h"

@interface ActionText:SpeakText
{
    id mouseDownTarget;          // target on left (primary) mouse down
    id mouseUpTarget;            // target on left (primary) mouse up
    id mouseDragTarget;          // target on left (primary) mouse drag
    id singleClickTarget;        // target on right single click
    id doubleClickTarget;        // target on right double click
    SEL mouseDownAction;         // action on left (primary) mouse down
    SEL mouseUpAction;           // action on left (primary) mouse up
    SEL mouseDragAction;         // action on left (primary) mouse drag
    SEL singleClickAction;       // action on right single click
    SEL doubleClickAction;       // action on right double click
    NXEventHandle eventHandle;   // handle to event driver system

    // constant-width font assumed
    NXCoord charWidth;

    id userCursor;               // NXImage of user cursor
    BOOL userCursorOnScreen;     // user cursor screen status

    // user cursor location
    int userCursorLine;
    int userCursorCol;
}

/* GENERAL METHODS */
- initFrame:(const NXRect *)frameRect text:(const char *)theText alignment:(int)mode;
- initFrame:(const NXRect *)frameRect;
- free;

/* CURSOR RELATED METHODS */
- convertPoint:(NXPoint *)aPoint toLine:(int *)line col:(int *)col;
- showUserCursorAt:(int)line :(int)col;
- showUserCursor;

/* OVERRIDEN RESPONDER METHODS */
- mouseDown:(NXEvent *)theEvent;

/* PERFORM ACTION METHODS */
- sendAction:(SEL)theAction to:theTarget;

/* TARGET/ACTION METHODS */
- setMouseDownTarget:anObject action:(SEL)anAction;
- setMouseUpTarget:anObject action:(SEL)anAction;
- setMouseDragTarget:anObject action:(SEL)anAction;
- setSingleClickTarget:anObject action:(SEL)anAction;
- setDoubleClickTarget:anObject action:(SEL)anAction;

- mouseDownTarget;
- mouseDragTarget;
- mouseUpTarget;
- singleClickTarget;
- doubleClickTarget;

- (SEL)mouseDownAction;
- (SEL)mouseDragAction;
- (SEL)mouseUpAction;
- (SEL)singleClickAction;
- (SEL)doubleClickAction;

/* SET METHODS */
- setUserCursorOnScreen:(BOOL)flag;

/* QUERY METHODS */
- (NXCoord)charWidth;

- (int)userCursorLine;
- (int)userCursorCol;
- (BOOL)userCursorOnScreen;

@end
