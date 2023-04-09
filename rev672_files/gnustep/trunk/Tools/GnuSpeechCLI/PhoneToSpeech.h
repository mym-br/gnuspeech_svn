//
//  PhoneToSpeech.h
//  (from GnuTTSServer)
//
//  Created by Dalmazio on 05/01/09.
//  Copyright 2009 Dalmazio Brisinda. All rights reserved.
//
//  Modified by mymatuda
//

#import <Foundation/Foundation.h>

#import <GnuSpeech/GnuSpeech.h>  // for struct _intonationParameters



@interface PhoneToSpeech : NSObject {
	NSDictionary *configuration;
	EventList *eventList;
	TRMSynthesizer *synthesizer;
	MModel *model;
	struct _intonationParameters intonationParameters;
}

- (id)initWithConfiguration:(NSDictionary*)configuration;
- (void)dealloc;

- (void)speakPhoneString:(NSString*)phoneString;

@end
