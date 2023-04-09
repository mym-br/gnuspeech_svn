/***************************************************************************
 *  Copyright 1991, 1992, 1993, 1994, 1995, 1996, 2001, 2002, 2007         *
 *    David R. Hill, Leonard Manzara, Craig Schock,                        *
 *    Steve Nygard                                                         *
 *                                                                         *
 *  This program is free software: you can redistribute it and/or modify   *
 *  it under the terms of the GNU General Public License as published by   *
 *  the Free Software Foundation, either version 3 of the License, or      *
 *  (at your option) any later version.                                    *
 *                                                                         *
 *  This program is distributed in the hope that it will be useful,        *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of         *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          *
 *  GNU General Public License for more details.                           *
 *                                                                         *
 *  You should have received a copy of the GNU General Public License      *
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.  *
 ***************************************************************************/

#import "CategoryList.h"

#import <Foundation/Foundation.h>
#import "MMCategory.h"

/*===========================================================================

	This Class currently adds no functionality to the List class.
	However, it is planned that this object will provide sorting functions
	to the MMCategory class.

===========================================================================*/

@implementation CategoryList

- (MMCategory *)findSymbol:(NSString *)searchSymbol;
{
    int count, index;
    MMCategory *aCategory;

    //NSLog(@"CategoryList searching for: %@\n", searchSymbol);

    count = [self count];
    for (index = 0; index < count; index++) {
        aCategory = [self objectAtIndex:index];
        if ([[aCategory name] isEqual:searchSymbol] == YES) {
            //NSLog(@"Found: %@\n", searchSymbol);
            return aCategory;
        }
    }

    //NSLog(@"Could not find: %@\n", searchSymbol);
    return nil;
}

@end
