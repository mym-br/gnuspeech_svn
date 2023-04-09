/*
 *    Filename:	MyText.h 
 *    Created :	Thu Jun  4 00:49:51 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *    LastEditDate was "Sat Jun  6 13:30:11 1992"
 *
 *    $Id: MyText.h,v 1.1 2002-03-21 16:49:51 rao Exp $
 *
 *    $Log: not supported by cvs2svn $
 * Revision 2.1  1992/06/10  14:25:24  vince
 * *** empty log message ***
 *
 */

#import <appkit/Text.h>

@interface MyText:Text
{
}


- keyDown:(NXEvent *)theEvent;
- mouseDown:(NXEvent *)theEvent;
- flagsChanged:(NXEvent *)theEvent;
- textDidGetKey:textObject charCode: (unsigned short int )charCode;
- textFlagsDidChange:textObject flags:(int) theflags keyCode:(unsigned int)keyCode;
- textDidMouseDown:textObject;

@end
