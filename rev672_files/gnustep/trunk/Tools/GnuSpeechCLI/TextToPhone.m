//
//  TextToPhone.m
//  (from GnuTTSServer)
//
//  Created by Dalmazio on 05/01/09.
//  Copyright 2009 Dalmazio Brisinda. All rights reserved.
//
//  Modified by mymatuda
//

#import "TextToPhone.h"

#import <Foundation/Foundation.h>

#import <GnuSpeech/GnuSpeech.h>

#import "config.h"



@implementation TextToPhone

- (id)init
{
	[super init];

	NSLog(@"TextToPhone init: Using simple dictionary.");
	pronunciationDictionary = [[GSSimplePronunciationDictionary mainDictionary] retain];
	[pronunciationDictionary loadDictionaryIfNecessary];
	if ([pronunciationDictionary version] != nil) {
		NSLog(@"TextToPhone init: Dictionary version %@", [pronunciationDictionary version]);
	}

	return self;
}

- (void)dealloc
{
	[pronunciationDictionary release];

	[super dealloc];
}

- (NSString*)phoneForText:(NSString*)text
{
	NSString *inputString = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	TTSParser *parser = [[TTSParser alloc] initWithPronunciationDictionary:pronunciationDictionary];
	NSString *resultString = [parser parseString:inputString];
	[parser release];

	return resultString;
}

@end
