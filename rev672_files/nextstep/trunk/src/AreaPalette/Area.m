/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:51 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/AreaPalette/Area.m,v $
$State: Exp $


$Log: not supported by cvs2svn $
# Revision 1.1.1.1  1993/09/27  19:34:52  len
# Initial archiving of AreaPalette source code.
#

******************************************************************************/


/*  HEADER FILES  ************************************************************/
#import "Area.h"
#import "AreaCell.h"



@implementation Area

/*  "CLASS VARIABLE" FOR SETTING CELL CLASS FOR THE CONTROL  */
static id areaCellClass;


+ initialize
{
    /*  SET THE CLASS VERSION NUMBER  */
    [Area setVersion:1];

    /*  SET GLOBAL CELL CLASS  */
    if (self == [Area class])
	areaCellClass = [AreaCell class];

    return self;
}



+ setCellClass:classId
{
    areaCellClass = classId;
    return self;
}



- initFrame:(const NXRect *)frameRect
{
    id oldCell;

    /*  DO SUPER CLASS INITIALIZATION  */
    [super initFrame:frameRect];

    /*  ALLOCATE ASSOCIATED CELL  */
    oldCell = [self setCell:[[areaCellClass allocFromZone:[self zone]] init]];
    [oldCell free];

    return self;
}



- (BOOL)acceptsFirstMouse
{
    return YES;
}



- setActiveEdge:(int)edge
{
    [cell setActiveEdge:edge];
    return [self display];
}

- (int)activeEdge
{
    return [cell activeEdge];
}



- setEdgeMin:(double)value
{
    [cell setEdgeMin:value];
    return [self display];
}

- (double)edgeMin
{
    return [cell edgeMin];
}



- setEdgeMax:(double)value
{
    [cell setEdgeMax:value];
    return [self display];
}

- (double)edgeMax
{
    return [cell edgeMax];
}



- setRangeMin:(double)value
{
    [cell setRangeMin:value];
    return [self display];
}

- (double)rangeMin
{
    return [cell rangeMin];
}



- setRangeMax:(double)value
{
    [cell setRangeMax:value];
    return [self display];
}

- (double)rangeMax
{
    return [cell rangeMax];
}



- setDoubleValue:(double)value
{
    [cell setDoubleValue:value];
    return [self display];
}

- (double)doubleValue
{
    return [cell doubleValue];
}



- setFloatValue:(float)value
{
    [cell setFloatValue:value];
    return [self display];
}

- (float)floatValue
{
    return [cell floatValue];
}



- setIntValue:(int)value
{
    [cell setIntValue:value];
    return [self display];
}

- (int)intValue
{
    return [cell intValue];
}



- setStringValue:(const char *)value
{
    [cell setStringValue:value];
    return [self display];
}

- (const char *)stringValue
{
    return [cell stringValue];
}



- takeDoubleValueFrom:sender;
{
    [cell setDoubleValue:[sender doubleValue]];
    return [self display];
}

- takeFloatValueFrom:sender
{
    [cell setFloatValue:[sender floatValue]];
    return [self display];
}

- takeIntValueFrom:sender;
{
    [cell setIntValue:[sender intValue]];
    return [self display];
}

- takeStringValueFrom:sender;
{
    [cell setStringValue:[sender stringValue]];
    return [self display];
}



- setGrayLevel:(float)value
{
    [cell setGrayLevel:value];
    return [self display];
}

- (float)grayLevel
{
    return [cell grayLevel];
}



- setBackgroundGray:(float)value
{
    [cell setBackgroundGray:value];
    return [self display];
}

- (float)backgroundGray
{
    return [cell backgroundGray];
}



- setBordered:(BOOL)flag
{
    [cell setBordered:flag];
    return [self display];
}

- (BOOL)bordered
{
    return [cell bordered];
}



- setBorderGray:(float)value
{
    [cell setBorderGray:value];
    return [self display];
}

- (float)borderGray
{
    return [cell borderGray];
}



- setDisplayOnly:(BOOL)flag
{
    [cell setDisplayOnly:flag];
    return self;
}

- (BOOL)displayOnly
{
    return [cell displayOnly];
}



- (const char *)getInspectorClassName
{
    return "AreaInspector";
}



- sizeToFit
{
    /*  OVERRIDDEN TO DO NOTHING  */
    return self;
}
@end
