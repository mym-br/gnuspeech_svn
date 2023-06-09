/*
 *    Filename:	CustSliderCell.m 
 *    Created :	Wed May 27 15:16:21 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *    LastEditDate was "Wed May 27 15:16:22 1992"
 *
 *    $Id: CustSliderCell.m,v 1.1 2002-03-21 16:49:51 rao Exp $
 *
 *    $Log: not supported by cvs2svn $
# Revision 2.1  1992/06/10  13:50:49  vince
# Initial Release
#
 */


/* Generated by Interface Builder */

#import "CustSliderCell.h"
#import <appkit/Control.h>

@implementation CustSliderCell

- setTarget2:anObject
{
    target2 = anObject;
    return self;
}

- setAction2:(SEL)aSelector
{
    action2 = aSelector;
    return self;
}

- target2
{
    return target2;
}

- (SEL)action2
{
    return action2;
}

- (BOOL)trackMouse:(NXEvent *)theEventTracks inRect:(const NXRect *)cellFrame ofView:controlView
{
    BOOL returnValue = [super trackMouse:theEventTracks inRect:cellFrame ofView:controlView];
    [controlView sendAction: action2 to:target2];
    return returnValue;
}

@end
