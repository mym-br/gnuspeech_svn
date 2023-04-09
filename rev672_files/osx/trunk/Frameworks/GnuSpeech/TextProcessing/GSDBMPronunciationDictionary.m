////////////////////////////////////////////////////////////////////////////////
//
//  Copyright 1991-2009 David R. Hill, Leonard Manzara, Craig Schock
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
//  GSDBMPronunciationDictionary.m
//  GnuSpeech
//
//  Created by Steve Nygard in 2004.
//
//  Version: 0.9.1
//
////////////////////////////////////////////////////////////////////////////////

#import "GSDBMPronunciationDictionary.h"
#import "NSFileManager-Extensions.h"
#import "GSSimplePronunciationDictionary.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>

@implementation GSDBMPronunciationDictionary

+ (NSString *)mainFilename;
{
    return [@"~/Library/Application Support/GnuSpeech/pronunciations" stringByExpandingTildeInPath];
}

+ (id)mainDictionary;
{
    static GSDBMPronunciationDictionary *_mainDictionary = nil;

    NSLog(@" > %s", _cmd);

    if (_mainDictionary == nil) {
        //NSString *path;

        _mainDictionary = [[GSDBMPronunciationDictionary alloc] initWithFilename:[self mainFilename]];
        //path = [[NSBundle bundleForClass:self] pathForResource:@"2.0eMainDictionary" ofType:@"dict"];
        //[_mainDictionary loadFromFile:path];
        //[_mainDictionary loadDictionary];
    }

    NSLog(@"<  %s", _cmd);

    return _mainDictionary;
}

+ (BOOL)createDatabase:(NSString *)aFilename fromSimpleDictionary:(GSSimplePronunciationDictionary *)simpleDictionary;
{
    NSDictionary *pronunciations;
    NSArray *allKeys;
    unsigned int count, index;
    DBM *newDB;
    NSString *key, *value;
    datum keyDatum, valueDatum;
    int result;

    pronunciations = [simpleDictionary pronunciations];
    allKeys = [pronunciations allKeys];

    [[NSFileManager defaultManager] createDirectoryAtPath:[aFilename stringByDeletingLastPathComponent] attributes:nil createIntermediateDirectories:YES];

    newDB = dbm_open([aFilename UTF8String], O_RDWR | O_CREAT, 0660);
    if (newDB == NULL) {
        perror("dbm_open()");
        return NO;
    }

    count = [allKeys count];
    NSLog(@"%d keys", count);

    for (index = 0; index < count; index++) {
        key = [allKeys objectAtIndex:index];
        value = [pronunciations objectForKey:key];
        //NSLog(@"%5d: key: %@, value: %@", index, key, value);

        keyDatum.dptr = (char *)[key UTF8String];
        keyDatum.dsize = strlen(keyDatum.dptr);

        valueDatum.dptr = (char *)[value UTF8String];
        valueDatum.dsize = strlen(valueDatum.dptr) + 1; // Let's get the zero byte too.

        result = dbm_store(newDB, keyDatum, valueDatum, DBM_REPLACE);
        if (result != 0)
            NSLog(@"Could not dbmstore(): index: %5d, key: %@, value: %@", index, key, value);
    }

    dbm_close(newDB);

    return YES;
}

- (id)initWithFilename:(NSString *)aFilename;
{
    if ([super initWithFilename:aFilename] == nil)
        return nil;

    db = NULL;

    return self;
}

- (void)dealloc;
{
    if (db != NULL) {
        dbm_close(db);
        db = NULL;
    }

    [super dealloc];
}

- (NSDate *)modificationDate;
{
    NSDictionary *attributes;

    attributes = [[NSFileManager defaultManager] fileAttributesAtPath:[filename stringByAppendingString:@".db"] traverseLink:YES];
    return [attributes fileModificationDate];
}

- (BOOL)loadDictionary;
{
    NSLog(@" > %s, db: %p", _cmd, db);
    NSParameterAssert(db == NULL);
    NSParameterAssert(filename != nil);

    NSLog(@"%s, filename: %@", _cmd, filename);
    db = dbm_open([filename UTF8String], O_RDONLY, 0660);
    if (db == NULL) {
        perror("dbm_open()");
        return NO;
    }

    NSLog(@"<  %s, db: %p", _cmd, db);

    return YES;
}

- (NSString *)lookupPronunciationForWord:(NSString *)aWord;
{
    datum keyDatum, valueDatum;

    keyDatum.dptr = (char *)[aWord UTF8String];
    keyDatum.dsize = strlen(keyDatum.dptr);

    valueDatum = dbm_fetch(db, keyDatum);
    if (valueDatum.dptr == NULL)
        return nil;

    return [NSString stringWithUTF8String:valueDatum.dptr];
}

@end
