/*
 *    Filename:	NiftyMatrixCat.h 
 *    Created :	Wed Jan  8 23:35:20 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *
 * LastEditDate "Tue Apr  7 21:36:31 1992"
 *
 * $Log: not supported by cvs2svn $
 * Revision 2.0  1992/04/08  03:43:23  vince
 * Initial-Release
 *
 *
 */


#import "NiftyMatrix.h"

@interface NiftyMatrix(NiftyMatrixCat)

- removeCellWithStringValue:(const char *)stringValue;
- removeAllCells;
- insertCellWithStringValue:(const char *)stringValue;
- toggleCellWithStringValue:(const char *)stringValue;
- grayAllCells;
- ungrayAllCells;
- unlockAllCells;
- findCellNamed:(const char *)stringValue;
@end
