/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:51 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/AreaPalette/AreaCell.m,v $
$State: Exp $


$Log: not supported by cvs2svn $
# Revision 1.2  1993/09/27  19:59:32  len
# Eliminated some commented-out code.
#
# Revision 1.1.1.1  1993/09/27  19:34:52  len
# Initial archiving of AreaPalette source code.
#

******************************************************************************/


/*  HEADER FILES  ************************************************************/
#import "AreaCell.h"
#import "Area.h"
#import <math.h>
#import <dpsclient/psops.h>



@implementation AreaCell

+ initialize
{
    [AreaCell setVersion:1];
    return self;
}



+ (BOOL)prefersTrackingUntilMouseUp
{
    return YES;
}



- init
{
    /*  DO REGULAR INITIALIZATION  */
    [super init];

    /*  THE CELL SENDS ACTIONS TO TARGET ON MOST MOUSE MOVEMENT  */
    [self sendActionOn:NX_MOUSEDOWNMASK|NX_MOUSEDRAGGEDMASK|NX_MOUSEUPMASK];

    /*  SET SENSIBLE DEFAULTS  */
    [self setType:NX_TEXTCELL];
    [self setActiveEdge:AC_TOPANDBOTTOM];
    [self setEdgeMin:0.0];
    [self setEdgeMax:1.0];
    [self setRangeMin:0.0];
    [self setRangeMax:1.0];
    [self setDoubleValue:0.5];
    [self setGrayLevel:NX_WHITE];
    [self setBackgroundGray:(5.0/6.0)];
    [self setBordered:YES];
    [self setBorderGray:NX_BLACK];
    [self setDisplayOnly:NO];


    return self;
}



- highlight:(const NXRect *)frame inView:view lit:(BOOL)flag
{
    /*  OVERRIDDEN TO DO NOTHING, SO ANNOYING FLASH IS ELIMINATED  */
    return self;
}



- setActiveEdge:(int)edge
{
    activeEdge = edge;
    return self;
}

- (int)activeEdge
{
    return activeEdge;
}



- setEdgeMin:(double)value
{
    edgeMin = value;

    /*  ERROR CHECKING  */
    if (rangeMin < value) rangeMin = value;
    if (currentValue < value) currentValue = value;
    if (rangeMax < value) rangeMax = value;
    if (edgeMax < value) edgeMax = value;

    /*  CALCULATE RANGE FROM EDGE TO EDGE  */
    edgeRange = edgeMax - edgeMin;

    return self;
}

- (double)edgeMin
{
    return edgeMin;
}



- setEdgeMax:(double)value
{
    edgeMax = value;

    /*  ERROR CHECKING  */
    if (edgeMin > value) edgeMin = value;
    if (rangeMin > value) rangeMin = value;
    if (currentValue > value) currentValue = value;
    if (rangeMax > value) rangeMax = value;

    /*  CALCULATE RANGE FROM EDGE TO EDGE  */
    edgeRange = edgeMax - edgeMin;

    return self;
}

- (double)edgeMax
{
    return edgeMax;
}



- setRangeMin:(double)value
{
    rangeMin = value;

    /*  ERROR CHECKING  */
    if (edgeMin > value) edgeMin = value;
    if (currentValue < value) currentValue = value;
    if (rangeMax < value) rangeMax = value;
    if (edgeMax < value) edgeMax = value;

    /*  CALCULATE RANGE FROM EDGE TO EDGE  */
    edgeRange = edgeMax - edgeMin;

    return self;
}

- (double)rangeMin
{
    return rangeMin;
}



- setRangeMax:(double)value
{
    rangeMax = value;

    /*  ERROR CHECKING  */
    if (edgeMin > value) edgeMin = value;
    if (rangeMin > value) rangeMax = value;
    if (currentValue > value) currentValue = value;
    if (edgeMax < value) edgeMax = value;

    /*  CALCULATE RANGE FROM EDGE TO EDGE  */
    edgeRange = edgeMax - edgeMin;

    return self;
}

- (double)rangeMax
{
    return rangeMax;
}



- setDoubleValue:(double)value
{
    /*  MAKE SURE VALUE IS IN RANGE  */
    if (value < rangeMin) value = rangeMin;
    else if (value > rangeMax) value = rangeMax;

    /*  SET CURRENT VALUE  */
    currentValue = value;

    /*  INVOKE SUPER CLASS TO SET contents IVAR  */
    return [super setDoubleValue:currentValue];
}

- (double)doubleValue
{
    return currentValue;
}



- setFloatValue:(float)value
{
    return [self setDoubleValue:(double)value];
}

- (float)floatValue
{
    return (float)currentValue;
}



- setIntValue:(int)value
{
    return [self setDoubleValue:(double)value];
}

- (int)intValue
{
    return (int)currentValue;
}



- setStringValue:(const char *)value
{
    [super setStringValue:value];
    return [self setDoubleValue:(double)atof(value)];
}

- (const char *)stringValue
{
    return [super stringValue];
}



- setGrayLevel:(float)value
{
    grayLevel = value;
    return self;
}

- (float)grayLevel
{
    return grayLevel;
}



- setBackgroundGray:(float)value
{
    backgroundGray = value;
    return self;
}

- (float)backgroundGray
{
    return backgroundGray;
}



- setBordered:(BOOL)flag
{
    bordered = flag;
    return self;
}

- (BOOL)bordered
{
    return bordered;
}



- setBorderGray:(float)value
{
    borderGray = value;
    return self;
}

- (float)borderGray
{
    return borderGray;
}



- setDisplayOnly:(BOOL)flag
{
    displayOnly = flag;
    return self;
}

- (BOOL)displayOnly
{
    return displayOnly;
}



- drawSelf:(const NXRect *)cellFrame inView:controlView
{
    return [self drawInside:cellFrame inView:controlView];
}

- drawInside:(const NXRect *)cellFrame inView:controlView
{
    double extent, offset;

    /*  COPY THE CELL FRAME INTO THE CURRENT RECTANGLE  */
    NXRect currentRectangle = *cellFrame;

    /*  DETERMINE THE EXTENT TO BE DRAWN  */
    if (edgeRange <= 0.0)
	extent = 0.0;
    else {
	extent = (currentValue - edgeMin) / edgeRange;
    }

    /*  DRAW BACKGROUND  */
    PSsetgray(backgroundGray);
    NXRectFill(cellFrame);
    
    /*  FIND CURRENT RECTANGLE  */
    switch (activeEdge) {
      case AC_TOP:
	currentRectangle.size.height =
	    rint(extent * currentRectangle.size.height);
	break;
      case AC_BOTTOM:
	offset = rint(NX_HEIGHT(&currentRectangle) - 
	    (NX_HEIGHT(&currentRectangle) * extent));
	currentRectangle.origin.y += offset;
	currentRectangle.size.height -= offset;
	break;
      case AC_LEFT:
	offset = rint(NX_WIDTH(&currentRectangle) -
	    (NX_WIDTH(&currentRectangle) * extent));
	currentRectangle.origin.x += offset;
	currentRectangle.size.width -= offset;
	break;
      case AC_RIGHT:
	currentRectangle.size.width =
	    rint(extent * currentRectangle.size.width);
	break;
      case AC_TOPANDBOTTOM:
	offset = NX_HEIGHT(&currentRectangle)
	    - (NX_HEIGHT(&currentRectangle) * extent);
	NXInsetRect(&currentRectangle, 0.0, rint(offset/2.0));
	break;
      case AC_LEFTANDRIGHT:
	offset = NX_WIDTH(&currentRectangle) - 
	    (NX_WIDTH(&currentRectangle) * extent);
	NXInsetRect(&currentRectangle, rint(offset/2.0), 0.0);
	break;
      default:
	break;
    }

    /*  DRAW CURRENT RECTANGLE  */
    PSsetgray(grayLevel);
    NXRectFill(&currentRectangle);

    /*  DRAW BORDER, IF ASKED FOR  */
    if (bordered) {
	PSsetgray(borderGray);
	NXFrameRect(&currentRectangle);
    }

    return self;
}



- (BOOL)trackMouse:(NXEvent *)event inRect:(const NXRect *)cellFrame
    ofView:controlView
{
    /*  GET THE SIZE OF THE CELL IN WHICH WE ARE TRACKING  */
    cellWidth = NX_WIDTH(cellFrame);
    cellHeight = NX_HEIGHT(cellFrame);

    /*  SET RECT TO NULL, SO WE TRACK MOUSE OVER LARGE AREA  */
    return [super trackMouse:event inRect:NULL ofView:controlView];
}



- (BOOL)startTrackingAt:(const NXPoint *)startPoint inView:controlView
{
    /*  RETURN IMMEDIATELY IF DISPLAY ONLY  */
    if (displayOnly)
	return NO;

    /*  ADJUST THE CURRENT VALUE ACCORDING TO CURRENT POINT  */
    [self adjustCurrentValue:startPoint->x :startPoint->y];

    /*  DISPLAY AS MOUSE MOVES  */
    [controlView display];

    /*  CONTINUE WITH CONTINUOUS TRACKING  */
    return YES;
}



- (BOOL)continueTracking:(const NXPoint *)lastPoint
    at:(const NXPoint *)currentPoint inView:controlView
{
    /*  RETURN IMMEDIATELY IF DISPLAY ONLY  */
    if (displayOnly)
	return NO;

    /*  ADJUST THE CURRENT VALUE ACCORDING TO CURRENT POINT  */
    [self adjustCurrentValue:currentPoint->x :currentPoint->y];

    /*  DISPLAY AS MOUSE MOVES  */
    [controlView display];

    /*  CONTINUE WITH CONTINUOUS TRACKING  */
    return YES;
}



- stopTracking:(const NXPoint *)lastPoint at:(const NXPoint *)endPoint
    inView:controlView mouseIsUp:(BOOL)flag
{
    /*  RETURN IMMEDIATELY IF DISPLAY ONLY  */
    if (displayOnly)
	return self;

    /*  ADJUST THE CURRENT VALUE ACCORDING TO CURRENT POINT  */
    [self adjustCurrentValue:endPoint->x :endPoint->y];

    /*  DISPLAY AS MOUSE MOVES  */
    [controlView display];

    return self;
}




- adjustCurrentValue:(double)x :(double)y
{
    double currentPoint = 0.0;

    /*  MAKE SURE POINTS ARE IN RANGE  */
    if (x < 0.0) x = 0.0;
    else if (x > cellWidth) x = cellWidth;

    if (y < 0.0) y = 0.0;
    else if (y > cellHeight) y = cellHeight;

    /*  CALCULATE CURRENT POINT, BASED ON CURSOR POSITION & ACTIVE EDGE  */
    switch (activeEdge) {
      case AC_TOP:
	currentPoint = ((y / cellHeight) * edgeRange) + edgeMin;
	break;
      case AC_BOTTOM:
	currentPoint = (((cellHeight - y) / cellHeight) * edgeRange) + edgeMin;
	break;
      case AC_LEFT:
	currentPoint = (((cellWidth - x) / cellWidth) * edgeRange) + edgeMin;
	break;
      case AC_RIGHT:
	currentPoint = ((x / cellWidth) * edgeRange) + edgeMin;
	break;
      case AC_TOPANDBOTTOM:
	currentPoint = (((fabs(y - cellHeight/2.0) * 2.0) / cellHeight) *
			edgeRange) + edgeMin;
	break;
      case AC_LEFTANDRIGHT:
	currentPoint = (((fabs(x - cellWidth/2.0) * 2.0) / cellWidth) *
			edgeRange) + edgeMin;
	break;
      default:
	break;
    }

    /*  LIMIT CURRENT VALUE TO WITHIN RANGE, AND SET THE CURRENT VALUE  */
    return [self setDoubleValue:currentPoint];
}



- (const char *)getInspectorClassName
{
    return "AreaCellInspector";
}



- read:(NXTypedStream *)stream
{
    int version;

    /*  DO NORMAL READING FROM STREAM  */
    [super read:stream];

    /*  GET THE CLASS VERSION NUMBER FROM THE STREAM  */
    version = NXTypedStreamClassVersion(stream, "AreaCell");

    /*  READ INSTANCE VARIABLES FROM STREAM  */
    if (version == 1) {
	NXReadTypes(stream, "iddddddffcfc", &activeEdge, &edgeMin, &edgeMax,
		   &edgeRange, &rangeMin, &rangeMax, &currentValue, &grayLevel,
		   &backgroundGray, &bordered, &borderGray, &displayOnly);
    }

    return self;
}

- write:(NXTypedStream *)stream
{
    /*  DO NORMAL WRITING TO STREAM  */
    [super write:stream];

    /*  WRITE INSTANCE VARIABLES TO STREAM  */
    NXWriteTypes(stream, "iddddddffcfc", &activeEdge, &edgeMin, &edgeMax,
		 &edgeRange, &rangeMin, &rangeMax, &currentValue, &grayLevel,
		 &backgroundGray, &bordered, &borderGray, &displayOnly);

    return self;
}

@end
