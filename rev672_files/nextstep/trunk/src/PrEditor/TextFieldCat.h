/*
 *    Filename:	TextFieldCat.h 
 *    Created :	Wed Jun  3 23:25:25 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *    LastEditDate was "Sat Jun  6 13:31:36 1992"
 *
 *    $Id: TextFieldCat.h,v 1.1 2002-03-21 16:49:51 rao Exp $
 *
 *    $Log: not supported by cvs2svn $
 * Revision 2.1  1992/06/10  14:18:34  vince
 * *** empty log message ***
 *
 */




#import <appkit/TextField.h>

@interface TextField(TextKeys)
- textDidGetKey:textObject charCode: (unsigned short int )charCode;
- textFlagsDidChange:textObject flags:(int) theflags keyCode:(unsigned int)keyCode;
- textDidMouseDown:textObject;
@end
