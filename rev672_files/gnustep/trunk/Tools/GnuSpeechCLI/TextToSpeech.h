//
//  TextToSpeech.h
//  (from GnuTTSServer)
//
//  Created by Dalmazio on 05/01/09.
//  Copyright 2009 Dalmazio Brisinda. All rights reserved.
//
//  Modified by mymatuda
//

#import <Foundation/Foundation.h>



@class TextToPhone, PhoneToSpeech;

@interface TextToSpeech : NSObject {
	TextToPhone *textToPhone;
	PhoneToSpeech *phoneToSpeech;
}

- (id)initWithConfiguration:(NSDictionary*)configuration;
- (void)dealloc;

- (void)speakText:(NSString*)text;

@end
