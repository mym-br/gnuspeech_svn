/*
 *    Filename:	TextFieldCat.m 
 *    Created :	Wed Jun  3 23:26:43 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *    LastEditDate was "Sat Jun  6 13:34:20 1992"
 *
 *    $Id: TextFieldCat.m,v 1.1 2002-03-21 16:49:51 rao Exp $
 *
 *    $Log: not supported by cvs2svn $
# Revision 2.1  1992/06/10  14:18:34  vince
# *** empty log message ***
#
 */


#import "TextFieldCat.h"

@implementation TextField(TextKeys)
- textDidGetKey:textObject charCode: (unsigned short int )charCode
{
    if ([textDelegate respondsTo:@selector(textDidGetKey:charCode:)]){
	[textDelegate textDidGetKey:textObject charCode: charCode];
    }
    return self;
}

- textFlagsDidChange:textObject flags:(int) theflags keyCode:(unsigned int)keyCode
{
    if ([textDelegate respondsTo:@selector(textFlagsDidChange:flags:keyCode:)]){
	[textDelegate textFlagsDidChange:textObject flags:theflags keyCode:keyCode];
    }
    return self;
}

- textDidMouseDown:textObject
{
    if ([textDelegate respondsTo:@selector(textDidMouseDown:)]){
	[textDelegate textDidMouseDown:textObject];
    }
    return self;

}
@end
