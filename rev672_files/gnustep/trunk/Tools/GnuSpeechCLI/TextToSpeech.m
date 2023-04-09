//
//  TextToSpeech.m
//  (from GnuTTSServer)
//
//  Created by Dalmazio on 05/01/09.
//  Copyright 2009 Dalmazio Brisinda. All rights reserved.
//
//  Modified by mymatuda
//

#import "TextToSpeech.h"
#import "TextToPhone.h"
#import "PhoneToSpeech.h"



@implementation TextToSpeech

- (id)initWithConfiguration:(NSDictionary*)configuration
{
	[super init];

	textToPhone = [[TextToPhone alloc] init];
	phoneToSpeech = [[PhoneToSpeech alloc] initWithConfiguration:configuration];

	return self;
}

- (void)dealloc
{
	[phoneToSpeech release];
	[textToPhone release];

	[super dealloc];
}

- (void)speakText:(NSString*)text
{
	NSString *phoneString = [textToPhone phoneForText:text];
	[phoneToSpeech speakPhoneString:phoneString];
}

@end
