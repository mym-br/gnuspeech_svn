////////////////////////////////////////////////////////////////////////////////
//
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard
//
//  Contributors: Steve Nygard
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
////////////////////////////////////////////////////////////////////////////////
//
//  This file is part of class-dump, a utility for examining the Objective-C 
//  segment of Mach-O files.
//
//  Copyright (C) 1997-1998, 2000-2001, 2004  Steve Nygard
//
//  NSScanner-Extensions.m
//  GnuSpeech
//
//  Created by Steve Nygard in 2004
//
//  Version: 0.9.1
//
////////////////////////////////////////////////////////////////////////////////

#import "NSScanner-Extensions.h"

#import <Foundation/Foundation.h>
#import "NSString-Extensions.h"

@implementation NSScanner (CDExtensions)

// gs for GnuSpeech
+ (NSCharacterSet *)gsBooleanIdentifierCharacterSet;
{
    static NSCharacterSet *identifierCharacterSet = nil;

    if (identifierCharacterSet == nil) {
        NSMutableCharacterSet *aSet;

        aSet = [[NSCharacterSet letterCharacterSet] mutableCopy];
        [aSet addCharactersInString:@"'"];
        identifierCharacterSet = [aSet copy];

        [aSet release];
    }

    return identifierCharacterSet;
}

- (NSString *)peekCharacter;
{
    //[self skipCharacters];

    if ([self isAtEnd] == YES)
        return nil;

    return [[self string] substringWithRange:NSMakeRange([self scanLocation], 1)];
}

- (unichar)peekChar;
{
    return [[self string] characterAtIndex:[self scanLocation]];
}

- (BOOL)scanCharacter:(unichar *)value;
{
    unichar ch;

    //[self skipCharacters];

    if ([self isAtEnd] == YES)
        return NO;

    ch = [[self string] characterAtIndex:[self scanLocation]];
    if (value != NULL)
        *value = ch;

    [self setScanLocation:[self scanLocation] + 1];

    return YES;
}

- (BOOL)scanCharacterIntoString:(NSString **)value;
{
    BOOL result;
    unichar ch;

    result = [self scanCharacter:&ch];
    if (result == YES)
        *value = [NSString stringWithUnichar:ch];

    return result;
}

- (BOOL)scanCharacterFromString:(NSString *)aString intoString:(NSString **)value;
{
    return [self scanCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:aString] intoString:value];
}

- (BOOL)scanCharacterFromSet:(NSCharacterSet *)set intoString:(NSString **)value;
{
    unichar ch;

    //[self skipCharacters];

    if ([self isAtEnd] == YES)
        return NO;

    ch = [[self string] characterAtIndex:[self scanLocation]];
    if ([set characterIsMember:ch] == YES) {
        if (value != NULL) {
            *value = [NSString stringWithUnichar:ch];
        }

        [self setScanLocation:[self scanLocation] + 1];
        return YES;
    }

    return NO;
}

// On 10.3 (7D24) the Foundation scanCharactersFromSet:intoString: inverts the set each call, creating an autoreleased CFCharacterSet.
// This cuts the total CFCharacterSet alloctions (when run on Foundation) from 161682 down to 17.

// This works for my purposes, but I haven't tested it to make sure it's fully compatible with the standard version.

- (BOOL)my_scanCharactersFromSet:(NSCharacterSet *)set intoString:(NSString **)value;
{
    NSRange matchedRange;
    unsigned int currentLocation;

    //[self skipCharacters];

    currentLocation = [self scanLocation];
    matchedRange.location = currentLocation;
    matchedRange.length = 0;

    while ([self isAtEnd] == NO) {
        unichar ch;

        ch = [[self string] characterAtIndex:currentLocation];
        if ([set characterIsMember:ch] == NO)
            break;

        currentLocation++;
        [self setScanLocation:currentLocation];
    }

    matchedRange.length = currentLocation - matchedRange.location;

    if (matchedRange.length == 0)
        return NO;

    if (value != NULL) {
        *value = [[self string] substringWithRange:matchedRange];
    }

    return YES;
}

- (BOOL)scanIdentifierIntoString:(NSString **)stringPointer;
{
    NSString *start, *remainder;

    if ([self scanString:@"?" intoString:stringPointer] == YES) {
        return YES;
    }

    if ([self scanCharacterFromSet:[NSCharacterSet letterCharacterSet] intoString:&start] == YES) {
        NSString *str;

        if ([self my_scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&remainder] == YES) {
            str = [start stringByAppendingString:remainder];
        } else {
            str = start;
        }

        if (stringPointer != NULL)
            *stringPointer = str;

        return YES;
    }

    return NO;
}

@end
