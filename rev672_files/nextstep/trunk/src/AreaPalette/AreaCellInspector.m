/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:51 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/AreaPalette/AreaCellInspector.m,v $
$State: Exp $


$Log: not supported by cvs2svn $
# Revision 1.1.1.1  1993/09/27  19:34:52  len
# Initial archiving of AreaPalette source code.
#

******************************************************************************/


/*  HEADER FILES  ************************************************************/
#import "AreaCellInspector.h"
#import "AreaCell.h"


/*  LOCAL DEFINES  ***********************************************************/
#define EDGE_MAX       0
#define RANGE_MAX      1
#define CURRENT_VALUE  2
#define RANGE_MIN      3
#define EDGE_MIN       4



@implementation AreaCellInspector

- init
{
    char buf[MAXPATHLEN+1];
    id bundle;

    /*  DO REGULAR INITIALIZATION  */
    [super init];

    /*  LOAD THE NIB FILE USING NXBUNDLE  */
    bundle = [NXBundle bundleForClass:[AreaCell class]];
    [bundle getPath:buf forResource:"AreaCellInspector" ofType:"nib"];
    [NXApp loadNibFile:buf owner:self withNames:NO fromZone:[self zone]];

    return self;
}



- resetControlValues
{
    /*  DISABLE DISPLAY, TO AVOID ANNOYING FLASH  */
    [window disableDisplay];

    /*  RESET CONTROL VALUES MATRIX  */
    [[controlValuesMatrix selectCellWithTag:EDGE_MAX]
        setDoubleValue:[object edgeMax]];
    [[controlValuesMatrix selectCellWithTag:RANGE_MAX]
        setDoubleValue:[object rangeMax]];
    [[controlValuesMatrix selectCellWithTag:CURRENT_VALUE]
        setDoubleValue:[object doubleValue]];
    [[controlValuesMatrix selectCellWithTag:RANGE_MIN]
        setDoubleValue:[object rangeMin]];
    [[controlValuesMatrix selectCellWithTag:EDGE_MIN]
        setDoubleValue:[object edgeMin]];

    /*  REENABLE THE DISPLAY  */
    [window reenableDisplay];
    [window displayIfNeeded];

    return self;
}



- ok:sender
{
    if (sender == controlValuesMatrix) {
	switch ([[sender selectedCell] tag]) {
	  case EDGE_MAX:
	    [object setEdgeMax:[[sender selectedCell] doubleValue]];
	    break;
	  case RANGE_MAX:
	    [object setRangeMax:[[sender selectedCell] doubleValue]];
	    break;
	  case CURRENT_VALUE:
	    [object setDoubleValue:[[sender selectedCell] doubleValue]];
	    break;
	  case RANGE_MIN:
	    [object setRangeMin:[[sender selectedCell] doubleValue]];
	    break;
	  case EDGE_MIN:
	    [object setEdgeMin:[[sender selectedCell] doubleValue]];
	    break;
	  default:
	    break;
	}
	/*  RESET CONTROL VALUES MATRIX  */
	[self resetControlValues];
    }
    /*  ACTIVE EDGE  */
    else if (sender == activeEdgeMatrix)
	[object setActiveEdge:[[sender selectedCell] tag]];
    /*  GRAY LEVEL SLIDER  */
    else if (sender == grayLevelSlider) {
	float value = [sender floatValue];
	[grayLevelField setFloatValue:value];
	[object setGrayLevel:value];
	[exampleArea setGrayLevel:value];
    }
    /*  GRAY LEVEL FIELD  */
    else if (sender == grayLevelField) {
	float value = [sender floatValue];
	if (value < 0.0) {
	    NXBeep();
	    value = 0.0;
	    [sender setFloatValue:value];
	}
	else if (value > 1.0) {
	    NXBeep();
	    value = 1.0;
	    [sender setFloatValue:value];
	}
	[grayLevelSlider setFloatValue:value];
	[object setGrayLevel:value];
	[exampleArea setGrayLevel:value];
    }
    /*  BACKGROUND GRAY SLIDER  */
    else if (sender == backgroundGraySlider) {
	float value = [sender floatValue];
	[backgroundGrayField setFloatValue:value];
	[object setBackgroundGray:value];
	[exampleArea setBackgroundGray:value];
    }
    /*  BACKGROUND GRAY FIELD  */
    else if (sender == backgroundGrayField) {
	float value = [sender floatValue];
	if (value < 0.0) {
	    NXBeep();
	    value = 0.0;
	    [sender setFloatValue:value];
	}
	else if (value > 1.0) {
	    NXBeep();
	    value = 1.0;
	    [sender setFloatValue:value];
	}
	[backgroundGraySlider setFloatValue:value];
	[object setBackgroundGray:value];
	[exampleArea setBackgroundGray:value];
    }
    /*  BORDER GRAY SLIDER  */
    else if (sender == borderGraySlider) {
	float value = [sender floatValue];
	[borderGrayField setFloatValue:value];
	[object setBorderGray:value];
	[exampleArea setBorderGray:value];
    }
    /*  BORDER GRAY FIELD  */
    else if (sender == borderGrayField) {
	float value = [sender floatValue];
	if (value < 0.0) {
	    NXBeep();
	    value = 0.0;
	    [sender setFloatValue:value];
	}
	else if (value > 1.0) {
	    NXBeep();
	    value = 1.0;
	    [sender setFloatValue:value];
	}
	[borderGraySlider setFloatValue:value];
	[object setBorderGray:value];
	[exampleArea setBorderGray:value];
    }
    /*  BORDERED SWITCH  */
    else if (sender == borderedSwitch) {
	[object setBordered:[sender state]];
	[exampleArea setBordered:[sender state]];
    }
    /*  DISPLAY ONLY SWITCH  */
    else if (sender == displayOnlySwitch)
	[object setDisplayOnly:[sender state]];
    /*  TAG FIELD  */
    else if (sender == tagField)
	[object setTag:[sender intValue]];

    return [super ok:sender];
}



- revert:sender
{
    /*  RESET CONTROL VALUES MATRIX  */
    [self resetControlValues];

    /*  RESET ACTIVE EDGE MATRIX  */
    [activeEdgeMatrix selectCellWithTag:[object activeEdge]];

    /*  RESET GRAY LEVEL CONTROLS  */
    [grayLevelSlider setFloatValue:[object grayLevel]];
    [grayLevelField setFloatValue:[object grayLevel]];
    [exampleArea setGrayLevel:[object grayLevel]];

    /*  RESET BACKGROUND GRAY CONTROLS  */
    [backgroundGraySlider setFloatValue:[object backgroundGray]];
    [backgroundGrayField setFloatValue:[object backgroundGray]];
    [exampleArea setBackgroundGray:[object backgroundGray]];

    /*  RESET BORDER GRAY CONTROLS  */
    [borderGraySlider setFloatValue:[object borderGray]];
    [borderGrayField setFloatValue:[object borderGray]];
    [exampleArea setBorderGray:[object borderGray]];

    /*  RESET BORDERED SWITCH  */
    [borderedSwitch setState:[object bordered]];
    [exampleArea setBordered:[object bordered]];

    /*  RESET DISPLAY ONLY SWITCH  */
    [displayOnlySwitch setState:[object displayOnly]];

    /*  RESET TAG FIELD  */
    [tagField setIntValue:[object tag]];

    return [super revert:sender];
}



- (BOOL)wantsButtons
{
    return NO;
}

@end
