/*
 *    Filename:	GrooveSliderCell.m 
 *    Created :	Tue Jun  8 15:55:24 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Mon Jul 25 22:33:54 1994"
 *    Copyright (c) 1994, Dale Brisinda. All rights reserved.
 */

#import "GrooveSliderCell.h"

/* General macros. */
#define DIFF(a,b) (ABS((a) - (b)))

/* Vertical retrace intervals per second. Yields approx. 0.014 event intervals. If the real vertical
 * retrace interval or the 0.014 event interval is different, this will not make much difference. This
 * value is simply used to adjust the value returned from NXClickTime, so that we can compare the time
 * elasped between a right mouse down and right mouse up with the NXClickTime for double click
 * recognition. Therefore, we only recognize single clicks if the time between these 2 events is
 * within the double click time defined in Preferences. This allows the value to be changed.
 */
#define VRETRACE_PSEC 68

@implementation GrooveSliderCell

- init
{
    [super init];
    mouseDown = NO;
    continuousKnob = NO;
    if (!(eventHandle = NXOpenEventStatus())) {
	NXLogError("Unable to open event status driver.");
    }
    [self setKnobThickness:1.0];

    // initialize targets and actions
    mouseDownTarget = mouseUpTarget = singleClickTarget = doubleClickTarget = nil;
    mouseDownAction = mouseUpAction = singleClickAction = doubleClickAction = (SEL)nil;
    return self;
}

- free
{
    NXCloseEventStatus(eventHandle);
    return [super free];
}

- awake
{
    [super awake];
    mouseDown = NO;
    if (!(eventHandle = NXOpenEventStatus())) {
	NXLogError("Unable to open event status driver.");
    }
    return self;
}

- read:(NXTypedStream *)typedStream
{
    [super read:typedStream];
    mouseDownTarget = NXReadObject(typedStream);
    mouseUpTarget = NXReadObject(typedStream);
    singleClickTarget = NXReadObject(typedStream);
    doubleClickTarget = NXReadObject(typedStream);
    NXReadTypes(typedStream, "::::c", &mouseDownAction, &mouseUpAction, &singleClickAction,
		&doubleClickAction, &continuousKnob);
    return self;
}

- write:(NXTypedStream *)typedStream
{
    [super write:typedStream];
    NXWriteObject(typedStream, mouseDownTarget);
    NXWriteObject(typedStream, mouseUpTarget);
    NXWriteObject(typedStream, singleClickTarget);
    NXWriteObject(typedStream, doubleClickTarget);
    NXWriteTypes(typedStream, "::::c", &mouseDownAction, &mouseUpAction, &singleClickAction,
		 &doubleClickAction, &continuousKnob);
    return self;
}

/* Override to add functionality which handles right mouse button click/key down events during
 * mouse dragging activity. The application event queue is examined for these additional events. If
 * they are found, the appropriate actions are taken via target/action methodology as defined by the
 * caller. Note that the terms "left" and "right" are a matter of convention, and "left" always refers
 * to the primary mouse button (depending on left or right-handedness). We assume the mouse buttons
 * have been differentiated. Returns YES, when the primary mouse button is released.
 *
 * Note that there is an interesting NeXTSTEP feature/bug in the event driver system. If the mouse
 * buttons are differentiated, and we rapidly click the left mouse button followed by the right mouse
 * button, the event driver system SHOULD set the number of clicks for the right mouse down event to
 * 1, but instead it sets the number of clicks to 2, which is clearly incorrect. Because of this
 * feature, the code here is made much more complex, since we have to do some of our own event
 * processing to make sure single and double clicks are handled correctly in special cases such as 
 * that mentioned above.
 */
- (BOOL)trackMouse:(NXEvent *)theEvent inRect:(const NXRect *)cellFrame ofView:aView
{
    NXPoint lastPoint, currentPoint;            // for continuing to track the mouse
    NXEvent *nextEvent, *tempEvent, eventPtr;   // handles to various events
    NXEvent firstRMouseDownEvent;               // holds event of first right mouse down
    BOOL doubleClick = NO;                      // is event a double click?
    BOOL firstRMouseUp = YES;                   // is event first right mouse up?
    BOOL validClickSpace = YES;                 // is single-click click space still valid?
    int rightMouseDown = 0;                     // holds the number of successive right mouse downs
    NXSize area;                                // holds single-click click space for mouse

    NXGetClickSpace(eventHandle, &area);
    nextEvent = theEvent;
    currentPoint = theEvent->location;
    mouseDown = YES;

    // convert location from window base coordinates to coordinates of aView
    [aView convertPoint:&currentPoint fromView:nil];

    if ([self startTrackingAt:&currentPoint inView:aView]) {     // send mouseDownAction on mouse down
	[aView sendAction:mouseDownAction to:mouseDownTarget];

	while (nextEvent->type != NX_LMOUSEUP) {   // main event processing loop
	    nextEvent = [NXApp getNextEvent:(NX_LMOUSEUPMASK |
					     NX_LMOUSEDRAGGEDMASK |
//					     NX_KEYDOWNMASK |
//					     NX_KEYUPMASK |
					     NX_RMOUSEDOWNMASK |
					     NX_RMOUSEUPMASK)];

	    // update last and current point
	    lastPoint = currentPoint;
	    currentPoint = nextEvent->location;

	    // convert location from window base coordinates to coordinates of aView
	    [aView convertPoint:&currentPoint fromView:nil];

	    switch (nextEvent->type) {
	      case NX_LMOUSEDRAGGED:
		if ([self continueTracking:&lastPoint at:&currentPoint 
			  inView:aView]) {   // send action only if groove continuous
		    [self incrementState];
		    if ([self isContinuous]) {   // only send if cell is continuous
			[aView sendAction:action to:target];
		    }
		}

		// Check the click space for single clicks during dragging. Now, if the user presses 
		// the right mouse button, drags the mouse, and returns to the location of the first 
		// right mouse down, then releases the right mouse button, we will detect that the 
		// click space between the mouse dragged locations and the first right mouse down
		// location is outside the valid click space. As a result, the single click should not
		// be recognized. See the documentation under "case: NX_RMOUSEUP" for more details.

		// This may seem kind of convoluted (because it is) but if rightMouseDown is not equal
		// to 0 then it CURRENTLY hold the number of right mouse downs that have occurred in
		// rapid succession LESS ONE. We anticipated the next mouse down in "case 
		// NX_RMOUSEDOWN". This is due to the NeXTSTEP event system feature mentioned 
		// throughout.

		if (rightMouseDown == 2 && 
		    (DIFF(nextEvent->location.x, firstRMouseDownEvent.location.x) > area.width ||
		     DIFF(nextEvent->location.y, firstRMouseDownEvent.location.y) > area.height)) {
		    
		    validClickSpace = NO;
		}
		break;

	      case NX_RMOUSEDOWN:

		// If the event structure field data.mouse.click == 1, then just ignore it, since so
		// far it is considered a single click, and will be identified when the corresponding 
		// right mouse up occurs. Note that if the event structure field data.mouse.click == 
		// 2, then the corresponding right mouse up event is yet to come. When it does come, 
		// the event structure field data.mouse.click will == 2 (or 1 if there was a delay in
		// letting the right mouse button up). We therefore need to indicate that the next
		// mouse up received should be thrown away, since it no longer serves a purpose. When
		// the right mouse up does occur, examining the variable doubleClick will allow case
		// NX_RMOUSEUP to determine if it should process the event or throw it away. Also, the
		// rightMouseDown check disallows a double click resulting from the first left mouse 
		// down followed by a right mouse down in rapid succession.

		// remember first right mouse down event for checking click space, and click time, and
		// assume valid click space initially
		firstRMouseDownEvent = *nextEvent;
		validClickSpace = YES;

		if (rightMouseDown) {   // must have at least one right mouse down (NeXTSTEP feature)
		    if (nextEvent->data.mouse.click == 2 || (nextEvent->data.mouse.click == 3 && 
							     rightMouseDown == 2)) {
			[aView sendAction:doubleClickAction to:doubleClickTarget];
			rightMouseDown = (rightMouseDown > 2 ? rightMouseDown : 3);
			doubleClick = YES;
		    } else if (nextEvent->data.mouse.click > 2) {   // disguise so single click is not
			doubleClick = YES;                          // recognized since > 2 clicks
		    }
		} else {   // for second occurrence of NX_MOUSEDOWN (anticipation)
		    rightMouseDown = 2;
		}
		break;

	      case NX_RMOUSEUP:

		// If doubleClick is true, then this right mouse up was part of a double click that
		// has already been processed. Therefore, just ignore the event, and reset the
		// doubleClick variable to NO.

		if (doubleClick) {
		    doubleClick = NO;
		    break;
		}

		// If the event structure field data.mouse.click == 2, then this is the right mouse up
		// which matches the right mouse down which previously resulted in a double click. We
		// just ignore it, since it no longer serves a purpose. Note that this event could
		// also be the first right mouse up, but may register with # clicks == 2 since its
		// corresponding right mouse down occurred immediately after the first left mouse down
		// which initiated the tracking session (NeXTSTEP feature). In this later case the 
		// event should trigger the action for a single click.

		if (nextEvent->data.mouse.click < 2 || firstRMouseUp) {

		    // If a right mouse down does not occur within the required time OR a right mouse
		    // down DOES occur within the required time, but the event structure field 
		    // data.mouse.click == 1, then we know we currently have a single click. Even 
		    // though we have a single click, we still need to check that the click is valid
		    // based on the single-click click space. If the click space is valid then we
		    // have a valid single click. If any of the above conditions are not satisfied, 
		    // then we just leave the event in the queue, since we have a double mouse click,
		    // which will be handled in the case NX_RMOUSEDOWN.

		    // Note, normal click-space detection is handled by the NeXTSTEP event system for
		    // events where the number of clicks is greater than 1. Here, we must handle it 
		    // ourselves since we act on the UP click rather than the DOWN click for single 
		    // click events, in order to be able to detect and act on double clicks INSTEAD. 
		    // The NeXTSTEP event system strings these click detections together, so that a 
		    // triple click, for example, is composed of a triple, double, and single click 
		    // -- and all are acted upon, in the order they are encountered. This is different
		    // from what we require, and is the reason why we check the click space for single
		    // clicks.

		    tempEvent = [NXApp peekNextEvent:(NX_RMOUSEDOWNMASK) 
				       into:&eventPtr
				       waitFor:NXClickTime(eventHandle) 
				       threshold:NX_MODALRESPTHRESHOLD];
		    if (!tempEvent || tempEvent->data.mouse.click == 1) {

			// we have a single click, but check click space and click time
			if (validClickSpace &&
			    DIFF(nextEvent->location.x, 
				 firstRMouseDownEvent.location.x) <= area.width &&
			    DIFF(nextEvent->location.y, 
				 firstRMouseDownEvent.location.y) <= area.height &&
			    DIFF(nextEvent->time, firstRMouseDownEvent.time) <= 
			    (long)(NXClickTime(eventHandle) * VRETRACE_PSEC)) {
			    
			    // single click is valid since it is within click space
			    [aView sendAction:singleClickAction to:singleClickTarget];
			}
		    }
		}
		firstRMouseUp = NO;
		break;

	      case NX_KEYDOWN:
 		// later
		break;

	      case NX_KEYUP:
		// later
		break;

	      case NX_LMOUSEUP:
		mouseDown = NO;
		[self stopTracking:&lastPoint at:&currentPoint inView:aView mouseIsUp:YES];
		[self incrementState];
		[aView sendAction:mouseUpAction to:mouseUpTarget];		    
		break;

	      default:
		break;
	    }
	}
    }
    return YES;
}


/* DRAWING METHODS */


- drawKnob:(const NXRect*)knobRect
{
    if (continuousKnob) {   // always draw knob
	PSsetgray(1.0);
	PSrectfill(knobRect->origin.x, 
		   knobRect->origin.y,
		   knobRect->size.width,
		   knobRect->size.height);
    } else {   // draw knob only when slider is active
	if (mouseDown) {
	    PSsetgray(1.0);
	    PSrectfill(knobRect->origin.x, 
		       knobRect->origin.y,
		       knobRect->size.width,
		       knobRect->size.height);
	}
    }
    return self;
}


/* DISPLAYING THE SLIDERCELL */


/* Continuously display the knob if flag is YES. Otherwise if NO, show the knob only when the left
 * mouse is down. Returns self. 
 */
- setContinuousKnob:(BOOL)flag
{
    continuousKnob = flag;
    [[self controlView] display];
    return self;
}


- (BOOL)continuousKnob
{
    return continuousKnob;
}

/* Shows the knob continuously, regardless of the current state of the slider cell. Returns self. */
- showKnob
{
    continuousKnob = YES;
    [[self controlView] display];
    return self;
}

/* Hides the knob regardless of the current state of the slider cell. Returns self. */
- hideKnob
{
    mouseDown = continuousKnob = NO;
    [[self controlView] display];
    return self;
}


/* TARGET/ACTION METHODS */


- setTarget:anObject action:(SEL)anAction
{
    target = anObject;
    action = anAction;
    return self;
}

- setMouseDownTarget:anObject action:(SEL)anAction
{
    mouseDownTarget = anObject;
    mouseDownAction = anAction;
    return self;
}

- setMouseUpTarget:anObject action:(SEL)anAction
{
    mouseUpTarget = anObject;
    mouseUpAction = anAction;
    return self;
}

- setSingleClickTarget:anObject action:(SEL)anAction
{
    singleClickTarget = anObject;
    singleClickAction = anAction;
    return self;
}

- setDoubleClickTarget:anObject action:(SEL)anAction
{
    doubleClickTarget = anObject;
    doubleClickAction = anAction;
    return self;
}

- setMouseDownTarget:anObject
{
    mouseDownTarget = anObject;
    return self;
}

- setMouseDownAction:(SEL)aSelector
{
    mouseDownAction = aSelector;
    return self;
}

- setMouseUpTarget:anObject
{
    mouseUpTarget = anObject;
    return self;
}

- setMouseUpAction:(SEL)aSelector
{
    mouseUpAction = aSelector;
    return self;
}

- setSingleClickTarget:theObject
{

    singleClickTarget = theObject;
    return self;
}

- setSingleClickAction:(SEL)theSelector
{
    singleClickAction = theSelector;
    return self;
}

- setDoubleClickTarget:theObject
{
    doubleClickTarget = theObject;
    return self;
}

- setDoubleClickAction:(SEL)theSelector
{
    doubleClickAction = theSelector;
    return self;
}

- mouseDownTarget
{
    return mouseDownTarget;
}

- (SEL)mouseDownAction
{
    return mouseDownAction;
}

- mouseUpTarget
{
    return mouseUpTarget;
}

- (SEL)mouseUpAction
{
    return mouseUpAction;
}

- singleClickTarget
{
    return singleClickTarget;
}

- (SEL)singleClickAction
{
    return singleClickAction;
}

- doubleClickTarget
{
    return doubleClickTarget;
}

- (SEL)doubleClickAction
{
    return doubleClickAction;
}

@end
