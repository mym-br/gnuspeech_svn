/***************************************************************************
 *  Copyright 1991, 1992, 1993, 1994, 1995, 1996, 2001, 2002, 2004, 2005,  *
 *            2007, 2008                                                   *
 *    David R. Hill, Leonard Manzara, Craig Schock,                        *
 *    Steve Nygard, Gregory John Casamento, Dalmazio Brisinda              *
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

#import "ApplicationDelegate.h"

#import <Foundation/Foundation.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSTextView.h>
#import <AppKit/NSButton.h>
#import <GnuSpeech/GnuSpeech.h>

@implementation ApplicationDelegate

+ (void)initialize;
{
}

- (id)init;
{
    [super init];
	
	textToPhone = [[MMTextToPhone alloc] init];

    return self;
}

- (void)dealloc;
{
	[textToPhone release];
	
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
{
}

- (IBAction)parseText:(id)sender;
{
    NSString *inputString, *resultString;

    NSLog(@"> %s", _cmd);

    inputString = [[inputTextView string] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSLog(@"parseText: inputString is: %@", inputString);

    resultString = [textToPhone phoneForText:inputString];

    [outputTextView setString:resultString];
    [outputTextView selectAll:nil];

    if ([copyPhoneStringCheckBox state])
        [outputTextView copy:nil];

    NSLog(@"<  %s", _cmd);
}

- (IBAction)lookupPronunication:(id)sender;
{
    NSString *word, *pronunciation;

    word = [[wordTextField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    pronunciation = [[GSSimplePronunciationDictionary mainDictionary] pronunciationForWord:word];
    //NSLog(@"word: %@, pronunciation: %@", word, pronunciation);
    if (pronunciation == nil) {
        //NSBeep();
        pronunciation = @"Pronunciation not found.";
    }

    [pronunciationTextField setStringValue:pronunciation];
}

@end
