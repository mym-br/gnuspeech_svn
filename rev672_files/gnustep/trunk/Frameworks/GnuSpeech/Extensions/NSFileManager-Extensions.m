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

#import "NSFileManager-Extensions.h"

#import <Foundation/Foundation.h>

@implementation NSFileManager (Extensions)

- (BOOL)createDirectoryAtPath:(NSString *)path attributes:(NSDictionary *)attributes createIntermediateDirectories:(BOOL)shouldCreateIntermediateDirectories;
{
    NSArray *pathComponents;
    unsigned int count, index;

    if (shouldCreateIntermediateDirectories == NO)
        return [self createDirectoryAtPath:path attributes:attributes];

    pathComponents = [path pathComponents];
    count = [pathComponents count];
    for (index = 1; index <= count; index++) {
        NSString *aPath;

        aPath = [NSString pathWithComponents:[pathComponents subarrayWithRange:NSMakeRange(0, index)]];
        if ([self fileExistsAtPath:aPath]) {
            //NSLog(@"path exists, skipping: %@", aPath);
            continue;
        }

        if ([self createDirectoryAtPath:aPath attributes:attributes] == NO) {
            //NSLog(@"failed to create directory: %@", aPath);
            return NO;
        }
    }

    return YES;
}

@end
