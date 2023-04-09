/*
 *    Filename:	MyText.m 
 *    Created :	Thu Jun  4 00:49:44 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *    LastEditDate was "Sat Jun  6 13:34:19 1992"
 *
 *    $Id: MyText.m,v 1.1 2002-03-21 16:49:51 rao Exp $
 *
 *    $Log: not supported by cvs2svn $
# Revision 2.1  1992/06/10  14:25:24  vince
# *** empty log message ***
#
 */


#import "MyText.h"

@implementation MyText

- keyDown:(NXEvent *)theEvent
{
    if ((!(theEvent->flags & NX_COMMANDMASK)) && [delegate respondsTo:@selector(textDidGetKey:charCode:)]){
	[delegate textDidGetKey:self charCode:theEvent->data.key.charCode];
    }
    return [super keyDown:theEvent];
}

- mouseDown:(NXEvent *)theEvent
{
    if ([delegate respondsTo:@selector(textDidMouseDown:)]){
	[delegate textDidMouseDown:self];
    }
    return [super mouseDown:theEvent];
}

- flagsChanged:(NXEvent *)theEvent
{
    if ([delegate respondsTo:@selector(textFlagsDidChange:flags:keyCode:)]){
	[delegate textFlagsDidChange:self flags:theEvent->flags keyCode:theEvent->data.key.keyCode];
    }
    return [super flagsChanged:theEvent];
}

- textDidGetKey:textObject charCode: (unsigned short int )charCode;
{
    return self;
}

- textFlagsDidChange:textObject flags:(int) theflags keyCode:(unsigned int)keyCode
{
    return self;
}

- textDidMouseDown:textObject
{
    return self;
}

@end
