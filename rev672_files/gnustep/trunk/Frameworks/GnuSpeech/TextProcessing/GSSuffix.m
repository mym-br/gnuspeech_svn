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

#import "GSSuffix.h"

#import <Foundation/Foundation.h>

@implementation GSSuffix

- (id)initWithSuffix:(NSString *)aSuffix replacementString:(NSString *)aReplacementString appendedPronunciation:(NSString *)anAppendedPronunciation;
{
    if ([super init] == nil)
        return nil;

    suffix = [aSuffix retain];
    replacementString = [aReplacementString retain];
    appendedPronunciation = [anAppendedPronunciation retain];

    return self;
}

- (void)dealloc;
{
    [suffix release];
    [replacementString release];
    [appendedPronunciation release];

    [super dealloc];
}

- (NSString *)suffix;
{
    return suffix;
}

- (NSString *)replacementString;
{
    return replacementString;
}

- (NSString *)appendedPronunciation;
{
    return appendedPronunciation;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@>[%p]: suffix: %@, replacementString: %@, appendedPronunciation: %@",
                     NSStringFromClass([self class]), self, suffix, replacementString, appendedPronunciation];
}

@end
