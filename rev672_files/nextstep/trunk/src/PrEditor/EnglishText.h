/*
 *    Filename:	EnglishText.h 
 *    Created :	Thu Feb  6 21:44:02 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *
 *  LastEditDate was "Thu Jun  4 00:43:52 1992"
 *
 * $Log: not supported by cvs2svn $
 * Revision 2.1  1992/06/10  13:53:33  vince
 * EnglishTextCell is no longer being used
 * a Custom TextObject (MyText) with new delegation
 * methods is being used to handle the filter
 * functions.
 *
 * Revision 2.0  1992/04/08  03:43:23  vince
 * Initial-Release
 *
 *
 */


/* Generated by Interface Builder */

#import <objc/Object.h>
#import "MyText.h"

@interface EnglishText:Object
{
    NXCharFilterFunc oldCharFilter; /* hold original filter func */

}
- (BOOL)textWillChange:textObject;
- textDidMouseDown:textObject;
@end
