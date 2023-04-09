/***************************************************************************
 *  Copyright 2009 Marcelo Y. Matuda                                       *
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

#import <Foundation/Foundation.h>
#import <Foundation/NSAutoreleasePool.h>

#import "TextToSpeech.h"

#include <stdio.h>

#include "config.h"



int main(int argc, const char *argv[])
{
	if (argc != 4) {
		fprintf(stderr, "Usage: %s config output_wav_file \"text\"\n", argv[0]);
		return 1;
	}

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSString *configPrefix = [NSString stringWithCString:argv[1] encoding:NSISOLatin1StringEncoding];
	NSString *outputFile   = [NSString stringWithCString:argv[2] encoding:NSISOLatin1StringEncoding];
	NSString *text         = [NSString stringWithCString:argv[3] encoding:NSISOLatin1StringEncoding];
	//NSString *text       = [NSString stringWithCString:argv[3] encoding:NSUTF8StringEncoding];

	// Load the program configuration.
	NSString* configPath = [[NSBundle mainBundle] pathForResource:configPrefix ofType:@"plist"];
	if (configPath == nil) {
		[NSException raise:NSGenericException format:@"Could not find the configuration file: %@.plist", configPrefix];
	}
	NSMutableDictionary *configuration = [[NSMutableDictionary alloc] initWithContentsOfFile:configPath];
	if (configuration == nil) {
		NSLog(@"Error: Could not load the configuration.");
		return 1;
	}
	[configuration setObject:outputFile forKey:CFG_KEY_OUTPUT_FILE];

	TextToSpeech *textToSpeech = [[TextToSpeech alloc] initWithConfiguration:configuration];
	[textToSpeech speakText:text];

	[textToSpeech release];
	[configuration release];
	//NSLog(@"Pool auto release count = %d", [pool autoreleaseCount]);
	//[pool drain]; // not implemented in GNUstep (2009-01)
	[pool release];

	return 0;
}
