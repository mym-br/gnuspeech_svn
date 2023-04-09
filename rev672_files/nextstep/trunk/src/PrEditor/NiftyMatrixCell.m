/*
 *    Filename:	NiftyMatrixCell.m 
 *    Created :	Wed Jan  8 23:36:39 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *
 * LastEditDate "Fri May 22 01:37:25 1992"
 *
 * $Log: not supported by cvs2svn $
# Revision 2.1  1992/06/10  14:29:07  vince
# drawInside:inView: and setFont: methods are now gone, instead
# the TextObject that is always present in a cell is being used
# to display the textValue of the cell and to toggle the color of
# the text. This is much more efficient than drawing the text
# with PostScript operators.
#
# Revision 2.0  1992/04/08  03:43:23  vince
# Initial-Release
#
 *
 */


// CustomCell.m
// By Jayson Adams, NeXT Developer Support Team
// You may freely copy, distribute and reuse the code in this example.
// NeXT disclaims any warranty of any kind, expressed or implied, as to its
// fitness for any particular use.

#import "NiftyMatrixCell.h"

#import <appkit/Text.h>

@implementation NiftyMatrixCell

/* instance methods */

- initTextCell:(const char *)string
{
    [super initTextCell:string];
    controlFlags.toggleValue = 1;
    controlFlags.locked = 0;
    cFlags1.alignment  = NX_CENTERED; /* Have the text be displayed centered */
    return self;
}

- toggle
{
    if (!controlFlags.locked){
	controlFlags.toggleValue = controlFlags.toggleValue ? 0 : 1 ;
    }
    return self;
}

- (int)toggleValue
{
    return controlFlags.toggleValue;
}

- setToggleValue:(int)value
{
    if (!controlFlags.locked && ((value == 1) || (value == 0))){
	controlFlags.toggleValue = value;
    }
    return self;
}

- lock
{
    controlFlags.locked = 1;
    return self;
}

- unlock
{
    controlFlags.locked = 0;
    return self;
}

/* The - drawInside:(const NXRect *)cellFrame inView:controlView method has been
 * Removed it was grossly inefficent. Considering that a Text object will be 
 * Present i might as well take advantage of it
 */
- setTextAttributes:textObj
{
    if (controlFlags.toggleValue){
	[textObj setTextGray:NX_BLACK];
    }else{
	[textObj setTextGray:NX_DKGRAY];
    }
    return self;
}

@end

