
#import <objc/Object.h>
#import <objc/List.h>
#import "Symbol.h"
#import <stdio.h>

/*===========================================================================

	Author: Craig-Richard Taube-Schock
		Copyright (c) 1994, Trillium Sound Research Incorporated.
		All Rights Reserved.

=============================================================================
*/

@interface SymbolList:List
{
}

- findSymbol:(const char *) searchSymbol;
- (int) findSymbolIndex:(const char *) searchSymbol;


@end
