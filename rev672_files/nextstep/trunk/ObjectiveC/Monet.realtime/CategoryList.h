
#import <objc/Object.h>
#import <objc/List.h>
#import "CategoryNode.h"
#import <stdio.h>

/*===========================================================================

	Author: Craig-Richard Taube-Schock
		Copyright (c) 1994, Trillium Sound Research Incorporated.
		All Rights Reserved.

=============================================================================
*/
@interface CategoryList:List
{
}

- findSymbol:(const char *) searchSymbol;
- addCategory:(const char *) newCategory;
- addNativeCategory:(const char *) newCategory;
- freeNativeCategories;
- readDegasFileFormat:(NXStream *) fp;
- printDataTo: (FILE *) fp;


/* BrowserManager List delegate Methods */
- addNewValue:(const char *) newValue;
- findByName:(const char *) name;
- changeSymbolOf:temp to:(const char *) name;

- read:(NXTypedStream *)stream;
- write:(NXTypedStream *)stream;

@end
