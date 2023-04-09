/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:51 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/AreaPalette/AreaCell.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
 * Revision 1.1.1.1  1993/09/27  19:34:52  len
 * Initial archiving of AreaPalette source code.
 *

******************************************************************************/


/*  HEADER FILES  ************************************************************/
#import <appkit/appkit.h>


/*  LOCAL DEFINES  ***********************************************************/
#define AC_TOP           0
#define AC_BOTTOM        1
#define AC_LEFT          2
#define AC_RIGHT         3
#define AC_TOPANDBOTTOM  4
#define AC_LEFTANDRIGHT  5



@interface AreaCell:ActionCell
{
    int activeEdge;

    double edgeMin;
    double edgeMax;
    double edgeRange;
    double rangeMin;
    double rangeMax;
    double currentValue;

    float grayLevel;
    float backgroundGray;
    BOOL  bordered;
    float borderGray;

    BOOL  displayOnly;

    /*  DON'T ARCHIVE THESE IVARS  */
    double cellWidth, cellHeight;
}

+ initialize;
+ (BOOL)prefersTrackingUntilMouseUp;
- init;

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
- setStringValue:(const char *)value;
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

- drawSelf:(const NXRect *)cellFrame inView:controlView;
- drawInside:(const NXRect *)cellFrame inView:controlView;
- adjustCurrentValue:(double)x :(double)y;

- (const char *)getInspectorClassName;

- read:(NXTypedStream *)stream;
- write:(NXTypedStream *)stream;

@end
