//
//  TextToPhone.h
//  (from GnuTTSServer)
//
//  Created by Dalmazio on 05/01/09.
//  Copyright 2009 Dalmazio Brisinda. All rights reserved.
//
//  Modified by mymatuda
//

#import <Foundation/Foundation.h>



@class GSPronunciationDictionary;

@interface TextToPhone : NSObject {
	GSPronunciationDictionary *pronunciationDictionary;
}

- (id)init;
- (void)dealloc;

- (NSString*)phoneForText:(NSString*)text;

@end
