/*
 *    Filename:	NiftyMatrixCell.h 
 *    Created :	Wed Jan  8 23:36:30 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *
 * LastEditDate "Fri May 22 00:50:53 1992"
 *
 * $Log: not supported by cvs2svn $
 * Revision 2.1  1992/06/10  14:29:07  vince
 * drawInside:inView: and setFont: methods are now gone, instead
 * the TextObject that is always present in a cell is being used
 * to display the textValue of the cell and to toggle the color of
 * the text. This is much more efficient than drawing the text
 * with PostScript operators.
 *
 * Revision 2.0  1992/04/08  03:43:23  vince
 * Initial-Release
 *
 *
 */


// By Jayson Adams, NeXT Developer Support Team
// You may freely copy, distribute and reuse the code in this example.
// NeXT disclaims any warranty of any kind, expressed or implied, as to its
// fitness for any particular use.

#import <appkit/SelectionCell.h>

@interface NiftyMatrixCell:SelectionCell
{
    struct _controlFlags {
	unsigned int        toggleValue:1; /* Indicates weather the Cell is Active or not Active */
        unsigned int        locked:1;      /* Indicates weather the Cell can change from Active
					    * to non Active or visa versa
					    */
        unsigned int        _unused:14;
    } controlFlags;
}

- initTextCell:(const char *)string;
- toggle;
- (int)toggleValue;
- setToggleValue:(int)value;
- lock;
- unlock;
- setTextAttributes:textObj;
@end
