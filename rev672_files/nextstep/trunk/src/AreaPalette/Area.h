/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:51 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/AreaPalette/Area.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
 * Revision 1.1.1.1  1993/09/27  19:34:51  len
 * Initial archiving of AreaPalette source code.
 *

******************************************************************************/


/*  HEADER FILES  ************************************************************/
#import <appkit/Control.h>



@interface Area:Control
{
}

+ initialize;
+ setCellClass:classId;
- initFrame:(const NXRect *)frameRect;

- setActiveEdge:(int)edge;
- (int)activeEdge;

- setEdgeMin:(double)value;
- (double)edgeMin;
- setEdgeMax:(double)value;
- (double)edgeMax;
- setRangeMin:(double)value;
- (double)rangeMin;
- setRangeMax:(double)value;
- (double)rangeMax;

- setDoubleValue:(double)value;
- (double)doubleValue;
- setFloatValue:(float)value;
- (float)floatValue;
- setIntValue:(int)value;
- (int)intValue;
- setStringValue:(const char *)string;
- (const char *)stringValue;

- setGrayLevel:(float)value;
- (float)grayLevel;
- setBackgroundGray:(float)value;
- (float)backgroundGray;
- setBordered:(BOOL)flag;
- (BOOL)bordered;
- setBorderGray:(float)value;
- (float)borderGray;

- setDisplayOnly:(BOOL)flag;
- (BOOL)displayOnly;

- (const char *)getInspectorClassName;
- sizeToFit;
@end
