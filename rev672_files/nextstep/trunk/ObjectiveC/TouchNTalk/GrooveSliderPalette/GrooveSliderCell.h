/*
 *    Filename:	GrooveSliderCell.h 
 *    Created :	Tue Jun  8 15:55:27 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    LastEditDate was "Wed Aug 25 21:17:46 1993"
 *
 * $Id: GrooveSliderCell.h,v 1.8 1993/08/27 04:00:02 dale Exp $
 *
 * $Log: GrooveSliderCell.h,v $
 * Revision 1.8  1993/08/27 04:00:02  dale
 * Added methods to manipulate when the knob is displayed.
 *
 * Revision 1.7  1993/07/14  22:19:31  dale
 * *** empty log message ***
 *
 * Revision 1.6  1993/06/16  07:49:26  dale
 * *** empty log message ***
 *
 * Revision 1.5  1993/06/11  08:43:59  dale
 * *** empty log message ***
 *
 * Revision 1.4  1993/06/11  01:02:31  dale
 * *** empty log message ***
 *
 * Revision 1.3  1993/06/11  00:01:49  dale
 * *** empty log message ***
 *
 * Revision 1.2  1993/06/10  00:10:32  dale
 * *** empty log message ***
 *
 */

#import <appkit/appkit.h>
#import <drivers/event_status_driver.h>

@interface GrooveSliderCell:SliderCell
{
    id mouseDownTarget,          // target on left (primary) mouse down
       mouseUpTarget,            // target on left (primary) mouse up
       singleClickTarget,        // target on right single click
       doubleClickTarget;        // target on right double click
    SEL mouseDownAction;         // action on left (primary) mouse down
    SEL mouseUpAction;           // action on left (primary) mouse up
    SEL singleClickAction;       // action on right single click
    SEL doubleClickAction;       // action on right double click
    BOOL mouseDown;              // only draw knob when mouse is down
    BOOL continuousKnob;         // determines whether to draw knob continuously
    NXEventHandle eventHandle;   // handle to event driver system
}

/* GENERAL METHODS */
- init;
- free;

/* TRACKING METHODS */
- (BOOL)trackMouse:(NXEvent *)theEvent inRect:(const NXRect *)cellFrame ofView:aView;

/* TARGET/ACTION METHODS */
- setTarget:anObject action:(SEL)anAction;
- setMouseDownTarget:anObject action:(SEL)anAction;
- setMouseUpTarget:anObject action:(SEL)anAction;
- setSingleClickTarget:anObject action:(SEL)anAction;
- setDoubleClickTarget:anObject action:(SEL)anAction;

- setMouseDownTarget:anObject;
- setMouseDownAction:(SEL)aSelector;
- setMouseUpTarget:anObject;
- setMouseUpAction:(SEL)aSelector;
- setSingleClickTarget:anObject;
- setSingleClickAction:(SEL)aSelector;
- setDoubleClickTarget:anObject;
- setDoubleClickAction:(SEL)aSelector;

- mouseDownTarget;
- (SEL)mouseDownAction;
- mouseUpTarget;
- (SEL)mouseUpAction;
- singleClickTarget;
- (SEL)singleClickAction;
- doubleClickTarget;
- (SEL)doubleClickAction;

/* CELL DRAWING METHODS */
- drawKnob:(const NXRect *)knobRect;

/* DISPLAYING THE SLIDERCELL */
- setContinuousKnob:(BOOL)flag;
- (BOOL)continuousKnob;
- showKnob;
- hideKnob;

/* UN/ARCHIVING METHODS */
- awake;
- read:(NXTypedStream *)typedStream;
- write:(NXTypedStream *)typedStream;

@end
