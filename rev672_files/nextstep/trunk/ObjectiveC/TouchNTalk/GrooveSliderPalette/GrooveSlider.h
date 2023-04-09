/*
 *    Filename:	GrooveSlider.h 
 *    Created :	Tue Jun  8 15:00:32 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Mon Jul 25 22:34:16 1994"
 *    Copyright (c) 1994, Dale Brisinda. All rights reserved.
 */

#import <appkit/appkit.h>

@interface GrooveSlider:Slider
{
}

/* FACTORY METHODS */
+ initialize;
+ setCellClass:classId;

/* INITIALIZING */
- initFrame:(NXRect *)frameRect;

/* DISPLAYING THE SLIDERCELL */
- setContinuousKnob:(BOOL)flag;
- (BOOL)continuousKnob;
- showKnob;
- hideKnob;

/* TARGET/ACTION METHODS */
- setTarget:anObject action:(SEL)anAction;
- setMouseDownTarget:anObject action:(SEL)anAction;
- setMouseUpTarget:anObject action:(SEL)anAction;
- setSingleClickTarget:anObject action:(SEL)anAction;
- setDoubleClickTarget:anObject action:(SEL)anAction;

- setMouseDownTarget:anObject;
- setMouseDownAction:(SEL)aSelector;
- setSingleClickTarget:anObject;
- setSingleClickAction:(SEL)aSelector;
- setDoubleClickTarget:anObject;
- setDoubleClickAction:(SEL)aSelector;
- setMouseUpTarget:anObject;
- setMouseUpAction:(SEL)aSelector;

- mouseDownTarget;
- (SEL)mouseDownAction;
- singleClickTarget;
- (SEL)singleClickAction;
- doubleClickTarget;
- (SEL)doubleClickAction;
- mouseUpTarget;
- (SEL)mouseUpAction;

@end
