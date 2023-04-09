/*
 *    Filename:	NiftyMatrixCat.m 
 *    Created :	Wed Jan  8 23:35:26 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *
 * LastEditDate "Tue Apr  7 21:36:37 1992"
 *
 * $Log: not supported by cvs2svn $
# Revision 2.0  1992/04/08  03:43:23  vince
# Initial-Release
#
 *
 */

#import "NiftyMatrixCat.h"
#import "NiftyMatrixCell.h"

#import <appkit/Cell.h>
#import <objc/List.h>
#import <objc/hashtable.h>

@implementation NiftyMatrix(NiftyMatrixCat)

- removeCellWithStringValue:(const char *)stringValue
{
    id list = [self cellList];
    id cellAt;
    int count;
    int i = 0;
    NXAtom strValue = NXUniqueString(stringValue);

    count = [list count];
    while (i < count) {
	cellAt = [list objectAt:i];
	if ( strValue == NXUniqueString([cellAt stringValue])){
	    [self removeRowAt: i andFree: YES];
	    break;
	}
	i++;
    }
    [self sizeToCells];
    return self;
}

- removeAllCells
{
    id list = [self cellList];
    int count;
    int i = 0;

    count = [list count];
    while (i < count) {
	[self removeRowAt: i andFree: YES];
	i++;
    }
    [self sizeToCells];
    return self;
}

- insertCellWithStringValue:(const char *)stringValue
{
    id newCell = nil;
    int rows,cols, count, i = 0;
    id cellAt;
    id list = [self cellList];
    BOOL found = NO;
    NXAtom strValue = NXUniqueString(stringValue);

    count = [list count];
    while (i < count) {
	cellAt = [list objectAt:i++];
	if (strValue == NXUniqueString([cellAt stringValue])){
	    found = YES;
	    break;
	}
    }

    if ( (count == 0) || (found != YES) ){
	[self getNumRows:&rows numCols:&cols];
	[self addRow];
	newCell = [self cellAt:rows:0];
	[newCell setStringValue:stringValue];
	[self sizeToCells];
    }
    [self clearSelectedCell];
    return self;
}

- toggleCellWithStringValue:(const char *)stringValue
{
    id list = [self cellList];
    id cellAt;
    int count;
    int i = 0;
    NXAtom strValue = NXUniqueString(stringValue);

    count = [list count];
    while (i < count) {
	cellAt = [list objectAt:i++];
	if (strValue == NXUniqueString([cellAt stringValue])){
	    [cellAt toggle];
	    break;
	}
    }
    return self;
}

- grayAllCells
{
    id list = [self cellList];
    id cellAt;
    int count;
    int i = 0;

    count = [list count];
    while (i < count) {
	cellAt = [list objectAt:i++];
	[cellAt setToggleValue:0];
    }
    return self;
}

- ungrayAllCells
{
    id list = [self cellList];
    id cellAt;
    int count;
    int i = 0;

    count = [list count];
    while (i < count) {
	cellAt = [list objectAt:i++];
	[cellAt setToggleValue:1];
    }

    return self;
}

- unlockAllCells
{
    id list = [self cellList];

/*********
    id cellAt;
    int count;
    int i = 0;

    count = [list count];
    while (i < count) {
	cellAt = [list objectAt:i++];
	[cellAt unlock];
    }
********/
    [list makeObjectsPerform:@selector(unlock)];
    return self;
}

- findCellNamed:(const char *)stringValue
{
    id list = [self cellList];
    id cellAt = nil;
    int count;
    int i = 0;
    NXAtom strValue = NXUniqueString(stringValue);

    count = [list count];
    while (i < count) {
	cellAt = [list objectAt:i++];
	if (strValue == NXUniqueString([cellAt stringValue])){
	    break;
	}else{
	    cellAt = nil;
	}
    }
    return cellAt;
}

@end
