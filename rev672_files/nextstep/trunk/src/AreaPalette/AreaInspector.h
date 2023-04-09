/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:51 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/AreaPalette/AreaInspector.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
 * Revision 1.1.1.1  1993/09/27  19:34:52  len
 * Initial archiving of AreaPalette source code.
 *

******************************************************************************/


/*  HEADER FILES  ************************************************************/
#import <appkit/appkit.h>
#import <apps/InterfaceBuilder.h>



@interface AreaInspector:IBInspector <IBInspectors>
{
    id	activeEdgeMatrix;
    id	backgroundGrayField;
    id	backgroundGraySlider;
    id	borderedSwitch;
    id	borderGrayField;
    id	borderGraySlider;
    id	controlValuesMatrix;
    id  displayOnlySwitch;
    id  exampleArea;
    id	grayLevelField;
    id	grayLevelSlider;
    id	tagField;
}

- init;

@end
