/*
 *    Filename:	GrooveSlider.m 
 *    Created :	Tue Jun  8 15:00:40 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    LastEditDate was "Wed Aug 25 21:07:33 1993"
 *
 * $Id: GrooveSlider.m,v 1.8 1993/08/27 04:00:02 dale Exp $
 *
 * $Log: GrooveSlider.m,v $
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
 * Revision 1.1  1993/06/08  22:03:26  dale
 * Initial revision
 *
 */

#import "GrooveSliderCell.h"
#import "GrooveSlider.h"

/* STATIC CLASS VARIABLES */
static id cellClass;

@implementation GrooveSlider

/* Initialize class to use GrooveSlideCell class as default cell class. Returns self. */
+ initialize
{
    /* class initialization code */
    cellClass = [GrooveSliderCell class];   // default cell class
    return self;
}

/* Explicitly set the cellClass to classId. Returns self. */
+ setCellClass:classId
{
    cellClass = classId;
    return self;
}

- initFrame:(NXRect *)frameRect
{
    [super initFrame:frameRect];
    [[self setCell:[[cellClass alloc] init]] free];   // free old cell (if any)
    return self;
}


/* DISPLAYING THE SLIDERCELL */


- setContinuousKnob:(BOOL)flag
{
    [cell setContinuousKnob:flag];
    return self;
}

- (BOOL)continuousKnob
{
    return [cell continuousKnob];
}

- showKnob
{
    [cell showKnob];
    return self;
}

- hideKnob
{
    [cell hideKnob];
    return self;
}


/* TARGET/ACTION METHODS */


- setTarget:anObject action:(SEL)anAction
{
    [cell setTarget:anObject action:(SEL)anAction];
    return self;
}

- setMouseDownTarget:anObject action:(SEL)anAction
{
    [cell setMouseDownTarget:anObject action:anAction];
    return self;
}

- setMouseUpTarget:anObject action:(SEL)anAction
{
    [cell setMouseUpTarget:anObject action:anAction];
    return self;
}

- setSingleClickTarget:anObject action:(SEL)anAction
{
    [cell setSingleClickTarget:anObject action:anAction];
    return self;
}

- setDoubleClickTarget:anObject action:(SEL)anAction
{
    [cell setDoubleClickTarget:anObject action:anAction];
    return self;
}

- setMouseDownTarget:anObject
{
    [cell setMouseDownTarget:anObject];
    return self;
}

- setMouseDownAction:(SEL)aSelector
{
    [cell setMouseDownAction:aSelector];
    return self;
}

- setSingleClickTarget:anObject
{
    [cell setSingleClickTarget:anObject];
    return self;
}

- setSingleClickAction:(SEL)aSelector
{
    [cell setSingleClickAction:aSelector];
    return self;
}

- setDoubleClickTarget:anObject
{
    [cell setDoubleClickTarget:anObject];
    return self;
}

- setDoubleClickAction:(SEL)aSelector
{
    [cell setDoubleClickAction:aSelector];
    return self;
}

- setMouseUpTarget:anObject
{
    [cell setMouseUpTarget:anObject];
    return self;
}

- setMouseUpAction:(SEL)aSelector
{
    [cell setMouseUpAction:aSelector];
    return self;
}

- mouseDownTarget
{
    return [cell mouseDownTarget];
}

- (SEL)mouseDownAction
{
    return [cell mouseDownAction];
}

- singleClickTarget
{
    return [cell singleClickTarget];
}

- (SEL)singleClickAction
{
    return [cell singleClickAction];
}

- doubleClickTarget
{
    return [cell doubleClickTarget];
}

- (SEL)doubleClickAction
{
    return [cell doubleClickAction];
}

- mouseUpTarget
{
    return [cell mouseUpTarget];
}

- (SEL)mouseUpAction
{
    return [cell mouseUpAction];
}

@end
