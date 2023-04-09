////////////////////////////////////////////////////////////////////////////////
//
//  Copyright 1991-2009 David R. Hill, Leonard Manzara, Craig Schock
//  
//  Contributors: Steve Nygard, Dalmazio Brisinda
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
//  TTSParserOld.m
//  GnuSpeech
//
//  Created by Steve Nygard in 2004.
//
//  Version: 0.9.1
//
////////////////////////////////////////////////////////////////////////////////

#import "TTSParserOld.h"

#import <Foundation/Foundation.h>
#import "NSScanner-Extensions.h"
#import "NSString-Extensions.h"

#import "GSPronunciationDictionary.h"
#import "TTSNumberPronunciations.h"

#define TTS_CHUNK_BOUNDARY        @"/c"
#define TTS_TONE_GROUP_BOUNDARY   @"//"
#define TTS_FOOT_BEGIN            @"/_"
#define TTS_TONIC_BEGIN           @"/*"
#define TTS_SECONDARY_STRESS      @"/\""
#define TTS_LAST_WORD             @"/l"
#define TTS_TAG_BEGIN             @"/t"
#define TTS_WORD_BEGIN            @"/w"
#define TTS_UTTERANCE_BOUNDARY    @"#"
#define TTS_MEDIAL_PAUSE          @"^"
#define TTS_LONG_MEDIAL_PAUSE     @"^ ^ ^"
#define TTS_SILENCE_PHONE         @"^"

#define TG_UNDEFINED          @"/x"
#define TG_STATEMENT          @"/0"
#define TG_EXCLAMATION        @"/1"
#define TG_QUESTION           @"/2"
#define TG_CONTINUATION       @"/3"
#define TG_HALF_PERIOD        @"/4"

#define TTS_STATE_UNDEFINED       (-1)
#define TTS_STATE_BEGIN           0
#define TTS_STATE_WORD            1
#define TTS_STATE_MEDIAL_PUNC     2
#define TTS_STATE_FINAL_PUNC      3
#define TTS_STATE_END             4
#define TTS_STATE_SILENCE         5
#define TTS_STATE_TAGGING         6

#define TTS_DEFAULT_END_PUNC @"."

TTSInputMode TTSInputModeFromString(NSString *str)
{
    if ([str isEqualToString:@"r"] || [str isEqualToString:@"R"]) {
        return TTSInputModeRaw;
    } else if ([str isEqualToString:@"l"] || [str isEqualToString:@"L"]) {
        return TTSInputModeLetter;
    } else if ([str isEqualToString:@"e"] || [str isEqualToString:@"E"]) {
        return TTSInputModeEmphasis;
    } else if ([str isEqualToString:@"t"] || [str isEqualToString:@"T"]) {
        return TTSInputModeTagging;
    } else if ([str isEqualToString:@"s"] || [str isEqualToString:@"S"]) {
        return TTSInputModeSilence;
    }

    return TTSInputModeUnknown;
}

static NSDictionary *_specialAcronyms = nil;

@implementation TTSParserOld

+ (void)initialize;
{
    NSString *path;

    path = [[NSBundle bundleForClass:[self class]] pathForResource:@"SpecialAcronyms" ofType:@"plist"];
    NSLog(@"path: %@", path);

    _specialAcronyms = [[NSDictionary alloc] initWithContentsOfFile:path];
    NSLog(@"_specialAcronyms: %@", [_specialAcronyms description]);
}

- (id)initWithPronunciationDictionary:(GSPronunciationDictionary *)aDictionary;
{
    if ([super init] == nil)
        return nil;

    mainDictionary = [aDictionary retain];
    //[mainDictionary loadDictionary];

    escapeCharacter = '%';

    return self;
}

- (void)dealloc;
{
    [mainDictionary release];

    [super dealloc];
}

- (NSString *)parseString:(NSString *)aString;
{
    NSMutableString *resultString;
	NSString * newString;

    NSLog(@" > %s", _cmd);

    NSLog(@"aString: %@", aString);
    newString = [self padCharactersInSet:[NSCharacterSet punctuationCharacterSet] 
								ofString:aString];  // temporary fix for punctuation issues -- dalmazio, Jan. 2009
	//[self markModes:aString];

    resultString = [NSMutableString string];
    [self finalConversion:newString resultString:resultString];	 // temporary fix for punctuation issues -- dalmazio, Jan. 2009	
    //[self finalConversion:aString resultString:resultString];

    NSLog(@"resultString: %@", resultString);

    NSLog(@"<  %s", _cmd);

    return resultString;
}

// Added as a temporary fix for punctuation problems, we pad all characters in the supplied character set (punctuation)
// with a space character. -- dalmazio, Jan. 2009.
- (NSString *) padCharactersInSet:(NSCharacterSet *)characterSet ofString:(NSString *)aString;
{
	unichar ch;
	NSMutableString * newString = [[[NSMutableString alloc] initWithCapacity:[aString length]*2] autorelease];

	for (int i = 0; i < [aString length]; i++) {
		ch = [aString characterAtIndex:i];
		if ([characterSet characterIsMember:ch])
			[newString appendFormat:@" %C ", ch];
		else
			[newString appendFormat:@"%C", ch];
	}
	return newString;
}


// TODO (2004-04-28): This wants to embed special characters (-1 through -11) in the output string...  We may need to do this differently, since we want to deal with characters, not bytes.
- (void)markModes:(NSString *)aString;
{
    NSMutableArray *modeStack;
    NSScanner *scanner;
    NSCharacterSet *escapeCharacterSet;
    NSMutableString *resultString;
    NSString *str;
    TTSInputMode currentMode;

    escapeCharacterSet = [NSCharacterSet characterSetWithCharactersInString:[NSString stringWithUnichar:escapeCharacter]];
    resultString = [NSMutableString string];

    modeStack = [[NSMutableArray alloc] init];
    currentMode = TTSInputModeNormal;
    [modeStack addObject:[NSNumber numberWithInt:currentMode]];

    scanner = [[NSScanner alloc] initWithString:aString];
    while ([scanner isAtEnd] == NO) {
        if ([scanner scanUpToCharactersFromSet:escapeCharacterSet intoString:&str] == YES)
            [resultString appendString:str];

        if ([scanner scanCharacterFromSet:escapeCharacterSet intoString:NULL] == YES) {
            if (currentMode == TTSInputModeRaw) {
                NSLog(@"Raw mode, do something...");
            } else {
                if ([scanner scanCharacterFromSet:escapeCharacterSet intoString:NULL] == YES) {
                    [resultString appendString:[NSString stringWithUnichar:escapeCharacter]];
                } else {
                    NSString *modeString;

                    if ([scanner scanCharacterIntoString:&modeString] == YES) {
                        TTSInputMode aMode;

                        NSLog(@"scanned mode: '%@'", modeString);
                        aMode = TTSInputModeFromString(modeString);
                        if (aMode == TTSInputModeUnknown) {
                            NSLog(@"Unknown mode, skipping...");
                        } else {
                            if ([scanner scanCharacterFromString:@"bB" intoString:NULL] == YES) {
                                NSLog(@"begin mode.");
                            } else if ([scanner scanCharacterFromString:@"eE" intoString:NULL] == YES) {
                                NSLog(@"end mode.");
                            } else {
                                NSLog(@"neither begin nor end mode.");
                            }
                        }
                    } else {
                        NSLog(@"End of string...");
                    }
                }
            }
        }
        break;
    }

    [scanner release];
    [modeStack release];

    NSLog(@"result string: '%@'", resultString);
}

- (void)stripPunctuationFromString:(NSString *)aString;
{
    NSLog(@" > %s", _cmd);
    NSLog(@"<  %s", _cmd);
}

// As part of the temporary fix for punctuation issues, we need to filter empty strings from the word string
// array so they are not rendered. -- dalmazio, Jan. 2009.
- (NSArray *) filterEmptyStringsFromArray:(NSArray *)theArray;
{	
	NSMutableArray * filteredArray = [[[NSMutableArray alloc] initWithCapacity:[theArray count]] autorelease];
	NSString * item;
	for (int i = 0; i < [theArray count]; i++) {
		item = [theArray objectAtIndex:i];
		if (![item isEqualToString:@""])
			[filteredArray addObject:item];
	}
	return filteredArray;
}

- (void)finalConversion:(NSString *)aString resultString:(NSMutableString *)resultString;
{
    NSArray *words;
    int previousState, currentState, nextState;
    unsigned int count, index;
    BOOL priorTonic = NO;
    unsigned int toneGroupMarkerLocation = NSNotFound;
    unsigned int lastWordEndLocation = NSNotFound;
    NSString *currentWord, *nextWord;

    previousState = TTS_STATE_BEGIN;

	words = [self filterEmptyStringsFromArray:[aString componentsSeparatedByString:@" "]];   // temporary fix -- dalmazio, Jan. 2009
	//words = [aString componentsSeparatedByString:@" "];	
	
    NSLog(@"words: %@", [words description]);

    count = [words count];
    if (count == 0) {
        currentState = TTS_STATE_END;
        NSLog(@"%s, No words.", _cmd);
    } else {
        for (index = 0; index < count; index++) {
            currentWord = [words objectAtIndex:index];
            if (index + 1 < count)
                nextWord = [words objectAtIndex:index + 1];
            else
                nextWord = nil;

            currentState = [self stateForWord:currentWord];
            nextState = [self stateForWord:nextWord];

            //NSLog(@"previousState: %d, currentState: %d (%@), nextState: %d (%@)", previousState, currentState, currentWord, nextState, nextWord);

            switch (currentState) {
              case TTS_STATE_WORD:
                  // Switch fall through desired:
                  switch (previousState) {
                    case TTS_STATE_BEGIN:
                        [resultString appendString:TTS_CHUNK_BOUNDARY];
                        [resultString appendString:@" "];
                    case TTS_STATE_FINAL_PUNC:
                        [resultString appendString:TTS_TONE_GROUP_BOUNDARY];
                        [resultString appendString:@" "];
                        priorTonic = NO;
                    case TTS_STATE_MEDIAL_PUNC:
                        toneGroupMarkerLocation = [resultString length];
                        [resultString appendString:TG_UNDEFINED];
                        [resultString appendString:@" "];
                    case TTS_STATE_SILENCE:
                        [resultString appendString:TTS_UTTERANCE_BOUNDARY];
                        [resultString appendString:@" "];
                  }

                  if (1) { // Normal Mode
                      [resultString appendString:TTS_WORD_BEGIN];
                      [resultString appendString:@" "];

                      switch (nextState) {
                        case TTS_STATE_MEDIAL_PUNC:
                        case TTS_STATE_FINAL_PUNC:
                        case TTS_STATE_END:
                            [resultString appendString:TTS_LAST_WORD];
                            [resultString appendString:@" "];
                            // Write word to result with tonic if no prior tonicization
                            [self expandWord:currentWord tonic:!priorTonic resultString:resultString];
                            break;
                        default:
                            // Write word to result without tonic
                            [self expandWord:currentWord tonic:NO resultString:resultString];
                      }
                  } else {
                  }

                  lastWordEndLocation = [resultString length];
                  break;

              case TTS_STATE_MEDIAL_PUNC:

                  // Switch fall through desired:
                  switch (previousState) {
                    case TTS_STATE_WORD:
                        if ([self shiftSilence] == YES) {
                        } else if (nextState != TTS_STATE_END && [nextWord startsWithLetter] == YES) {
                            [resultString appendString:TTS_UTTERANCE_BOUNDARY];
                            [resultString appendString:@" "];
                            if ([currentWord isEqualToString:@","] == YES) {
                                [resultString appendString:TTS_MEDIAL_PAUSE];
                            } else {
                                [resultString appendString:TTS_LONG_MEDIAL_PAUSE];
                            }
                            [resultString appendString:@" "];
                        } else if (nextState == TTS_STATE_END) {
                            [resultString appendString:TTS_UTTERANCE_BOUNDARY];
                            [resultString appendString:@" "];
                        }

                    case TTS_STATE_SILENCE:
                        [resultString appendString:TTS_TONE_GROUP_BOUNDARY];
                        [resultString appendString:@" "];
                        priorTonic = NO;
                        if (toneGroupMarkerLocation != NSNotFound)
                            [resultString replaceCharactersInRange:NSMakeRange(toneGroupMarkerLocation, 2)
                                          withString:[self toneGroupStringForPunctuation:currentWord]];
                          else
                              NSLog(@"Warning: Couldn't set tone group");
                        toneGroupMarkerLocation = NSNotFound;
                  }
                  break;

              case TTS_STATE_FINAL_PUNC:
                  if (previousState == TTS_STATE_WORD) {
                      if ([self shiftSilence] == YES) {
                      } else {
                          [resultString appendFormat:@"%@ %@ %@ ", TTS_UTTERANCE_BOUNDARY, TTS_TONE_GROUP_BOUNDARY, TTS_CHUNK_BOUNDARY];
                          priorTonic = NO;
                          if (toneGroupMarkerLocation != NSNotFound)
                              [resultString replaceCharactersInRange:NSMakeRange(toneGroupMarkerLocation, 2)
                                            withString:[self toneGroupStringForPunctuation:currentWord]];
                          else
                              NSLog(@"Warning: Couldn't set tone group");
                          toneGroupMarkerLocation = NSNotFound;
                      }
                  } else if (previousState == TTS_STATE_SILENCE) {
                  }
                  break;

              case TTS_STATE_SILENCE:
                  break;

              case TTS_STATE_TAGGING:
                  break;

              case TTS_STATE_END:
                  break;

			  default:  // added as temporary fix -- dalmazio, Jan. 2009
				  break;		
            }

            previousState = currentState;
        }
    }

    switch (previousState) {
      case TTS_STATE_MEDIAL_PUNC:
          [resultString appendString:TTS_CHUNK_BOUNDARY];
          break;

          // Switch fall through desired:
      case TTS_STATE_WORD:
          [resultString appendString:TTS_UTTERANCE_BOUNDARY];
          [resultString appendString:@" "];
      case TTS_STATE_SILENCE:
          [resultString appendString:TTS_TONE_GROUP_BOUNDARY];
          [resultString appendString:@" "];
          [resultString appendString:TTS_CHUNK_BOUNDARY];
          priorTonic = NO;
          if (toneGroupMarkerLocation != NSNotFound)
              [resultString replaceCharactersInRange:NSMakeRange(toneGroupMarkerLocation, 2)
                            withString:[self toneGroupStringForPunctuation:TTS_DEFAULT_END_PUNC]];
          else
              NSLog(@"Warning: Couldn't set tone group");
          toneGroupMarkerLocation = NSNotFound;
          break;

      case TTS_STATE_BEGIN:
          break;
			
	  default:  // added as temporary fix -- dalmazio, Jan. 2009
		  break;					
    }
}

- (int)stateForWord:(NSString *)word;
{
    if (word == nil)
        return TTS_STATE_END;

    if ([word startsWithLetter] == YES)
        return TTS_STATE_WORD;

    if ([word isEqualToString:@"."] || [word isEqualToString:@"!"] || [word isEqualToString:@"?"]) {	
        return TTS_STATE_FINAL_PUNC;
		
    } else if ([word isEqualToString:@";"] || [word isEqualToString:@":"] || [word isEqualToString:@","]) {
        return TTS_STATE_MEDIAL_PUNC;
    }

    return TTS_STATE_UNDEFINED;
}

- (void)expandWord:(NSString *)word tonic:(BOOL)isTonic resultString:(NSMutableString *)resultString;
{
    BOOL isPossessive;
    NSString *pronunciation = nil;
    unsigned int lastFootBegin;
    NSString *lastPhoneme = nil;

    // Strip of possessive if word ends with 's
    isPossessive = [word hasSuffix:@"'s"];
    if (isPossessive == YES)
        word = [word substringToIndex:[word length] - 2];

    if ([word length] == 1 && [word startsWithLetter] == YES) {
        if ([word isEqualToString:@"a"] == YES) {
            pronunciation = @"uh";
        } else {
            pronunciation = [self degenerateString:word];
        }
        // dictionary = TTS_LETTER_TO_SOUND;
    } else if ([word isAllUpperCase] == YES) {
        pronunciation = [_specialAcronyms objectForKey:word];
        if (pronunciation == nil)
            pronunciation = [self degenerateString:word];
        // dictionary = TTS_LETTER_TO_SOUND;
    } else {
        pronunciation = [mainDictionary pronunciationForWord:[word lowercaseString]];
        // TODO (2004-04-29): And that should set the dictionary
    }

    lastFootBegin = NSNotFound;
    if (isTonic == YES && [pronunciation containsPrimaryStress] == NO) {
        NSString *convertedStress;

        convertedStress = [pronunciation convertedStress];
        if (convertedStress != nil) {
            // For example, "saltwater"
            pronunciation = convertedStress;
        } else {
            // For example, "times"
            lastFootBegin = [resultString length];
            [resultString appendString:TTS_FOOT_BEGIN];
        }
    }

    // TODO (2004-04-30): We could preprocess the dictionary to do these transformations on the pronunciations.
    if (pronunciation != nil) {
        NSScanner *scanner;

        scanner = [[NSScanner alloc] initWithString:pronunciation];
        // TODO (2004-04-30): I'm assuming there are no spaces in the pronunciation.

        while ([scanner isAtEnd] == NO) {
            if ([scanner scanString:@"'" intoString:NULL] == YES) {
                lastFootBegin = [resultString length];
                [resultString appendString:TTS_FOOT_BEGIN];
                lastPhoneme = nil;
            } else if ([scanner scanString:@"\"" intoString:NULL] == YES) {
                [resultString appendString:TTS_SECONDARY_STRESS];
                lastPhoneme = nil;
            } else if ([scanner scanString:@"_" intoString:NULL] == YES) {
                [resultString appendString:@"_"];
                lastPhoneme = nil;
            } else if ([scanner scanString:@"." intoString:NULL] == YES) {
                [resultString appendString:@"."];
                lastPhoneme = nil;
            } else if ([scanner scanCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:&lastPhoneme] == YES) {
                [resultString appendString:lastPhoneme];
            }
        }

        [scanner release];
    } else {
        NSLog(@"Warning: No pronunciation for: %@", word);
        // Insert a noticable sound to make it obvious that something is missing.
        [resultString appendString:@"/_b_z_z_z_z_t_uh"];
    }
    //[resultString appendString:pronunciation];

    if (isPossessive == YES) {
        if ([lastPhoneme isEqualToString:@"f"]
            || [lastPhoneme isEqualToString:@"k"]
            || [lastPhoneme isEqualToString:@"p"]
            || [lastPhoneme isEqualToString:@"t"]
            || [lastPhoneme isEqualToString:@"th"]) {
            [resultString appendString:@"_s"];
        } else if ([lastPhoneme isEqualToString:@"ch"]
                   || [lastPhoneme isEqualToString:@"j"]
                   || [lastPhoneme isEqualToString:@"s"]
                   || [lastPhoneme isEqualToString:@"sh"]
                   || [lastPhoneme isEqualToString:@"z"]
                   || [lastPhoneme isEqualToString:@"zh"]) {
            [resultString appendString:@".uh_z"];
        } else {
            [resultString appendString:@"_z"];
        }
    }

    // Add space after word
    [resultString appendString:@" "];

    // If tonic, convert last foot marker to tonic marker
    if (isTonic == YES && lastFootBegin != NSNotFound) {
        [resultString replaceCharactersInRange:NSMakeRange(lastFootBegin, 2) withString:TTS_TONIC_BEGIN];
    }
}

// Returns a string which contains a character-by-character pronunciation for the string pointed at by the argument word.

- (NSString *)degenerateString:(NSString *)word;
{
    NSMutableString *resultString;
    unsigned int length, index;
    unichar ch;

    resultString = [NSMutableString string];
    length = [word length];
    for (index = 0; index < length; index++) {
        ch = [word characterAtIndex:index];
        switch (ch) {
          case ' ': [resultString appendString:PR_BLANK];                break;
          case '!': [resultString appendString:PR_EXCLAMATION_POINT];    break;
          case '"': [resultString appendString:PR_DOUBLE_QUOTE];         break;
          case '#': [resultString appendString:PR_NUMBER_SIGN];          break;
          case '$': [resultString appendString:PR_DOLLAR_SIGN];          break;
          case '%': [resultString appendString:PR_PERCENT_SIGN];         break;
          case '&': [resultString appendString:PR_AMPERSAND];            break;
          case '\'':[resultString appendString:PR_SINGLE_QUOTE];         break;
          case '(': [resultString appendString:PR_OPEN_PARENTHESIS];     break;
          case ')': [resultString appendString:PR_CLOSE_PARENTHESIS];    break;
          case '*': [resultString appendString:PR_ASTERISK];             break;
          case '+': [resultString appendString:PR_PLUS_SIGN];            break;
          case ',': [resultString appendString:PR_COMMA];                break;
          case '-': [resultString appendString:PR_HYPHEN];               break;
          case '.': [resultString appendString:PR_PERIOD];               break;
          case '/': [resultString appendString:PR_SLASH];                break;
          case '0': [resultString appendString:PR_ZERO];                 break;
          case '1': [resultString appendString:PR_ONE];                  break;
          case '2': [resultString appendString:PR_TWO];                  break;
          case '3': [resultString appendString:PR_THREE];                break;
          case '4': [resultString appendString:PR_FOUR];                 break;
          case '5': [resultString appendString:PR_FIVE];                 break;
          case '6': [resultString appendString:PR_SIX];                  break;
          case '7': [resultString appendString:PR_SEVEN];                break;
          case '8': [resultString appendString:PR_EIGHT];                break;
          case '9': [resultString appendString:PR_NINE];                 break;
          case ':': [resultString appendString:PR_COLON];                break;
          case ';': [resultString appendString:PR_SEMICOLON];            break;
          case '<': [resultString appendString:PR_OPEN_ANGLE_BRACKET];   break;
          case '=': [resultString appendString:PR_EQUAL_SIGN];           break;
          case '>': [resultString appendString:PR_CLOSE_ANGLE_BRACKET];  break;
          case '?': [resultString appendString:PR_QUESTION_MARK];        break;
          case '@': [resultString appendString:PR_AT_SIGN];              break;
          case 'A':
          case 'a': [resultString appendString:PR_A];                    break;
          case 'B':
          case 'b': [resultString appendString:PR_B];                    break;
          case 'C':
          case 'c': [resultString appendString:PR_C];                    break;
          case 'D':
          case 'd': [resultString appendString:PR_D];                    break;
          case 'E':
          case 'e': [resultString appendString:PR_E];                    break;
          case 'F':
          case 'f': [resultString appendString:PR_F];                    break;
          case 'G':
          case 'g': [resultString appendString:PR_G];                    break;
          case 'H':
          case 'h': [resultString appendString:PR_H];                    break;
          case 'I':
          case 'i': [resultString appendString:PR_I];                    break;
          case 'J':
          case 'j': [resultString appendString:PR_J];                    break;
          case 'K':
          case 'k': [resultString appendString:PR_K];                    break;
          case 'L':
          case 'l': [resultString appendString:PR_L];                    break;
          case 'M':
          case 'm': [resultString appendString:PR_M];                    break;
          case 'N':
          case 'n': [resultString appendString:PR_N];                    break;
          case 'O':
          case 'o': [resultString appendString:PR_O];                    break;
          case 'P':
          case 'p': [resultString appendString:PR_P];                    break;
          case 'Q':
          case 'q': [resultString appendString:PR_Q];                    break;
          case 'R':
          case 'r': [resultString appendString:PR_R];                    break;
          case 'S':
          case 's': [resultString appendString:PR_S];                    break;
          case 'T':
          case 't': [resultString appendString:PR_T];                    break;
          case 'U':
          case 'u': [resultString appendString:PR_U];                    break;
          case 'V':
          case 'v': [resultString appendString:PR_V];                    break;
          case 'W':
          case 'w': [resultString appendString:PR_W];                    break;
          case 'X':
          case 'x': [resultString appendString:PR_X];                    break;
          case 'Y':
          case 'y': [resultString appendString:PR_Y];                    break;
          case 'Z':
          case 'z': [resultString appendString:PR_Z];                    break;
          case '[': [resultString appendString:PR_OPEN_SQUARE_BRACKET];  break;
          case '\\':[resultString appendString:PR_BACKSLASH];            break;
          case ']': [resultString appendString:PR_CLOSE_SQUARE_BRACKET]; break;
          case '^': [resultString appendString:PR_CARET];                break;
          case '_': [resultString appendString:PR_UNDERSCORE];           break;
          case '`': [resultString appendString:PR_GRAVE_ACCENT];         break;
          case '{': [resultString appendString:PR_OPEN_BRACE];           break;
          case '|': [resultString appendString:PR_VERTICAL_BAR];         break;
          case '}': [resultString appendString:PR_CLOSE_BRACE];          break;
          case '~': [resultString appendString:PR_TILDE];                break;
          default:  [resultString appendString:PR_UNKNOWN];              break;
        }
    }

    return resultString;
}

- (BOOL)shiftSilence;
{
    // TODO (2004-04-30): Convert original function
    return NO;
}

- (NSString *)toneGroupStringForPunctuation:(NSString *)str;
{
    if ([str isEqualToString:@"."]) {
        return TG_STATEMENT;
    } else if ([str isEqualToString:@"!"]) {
        return TG_EXCLAMATION;
    } else if ([str isEqualToString:@"?"]) {
        return TG_QUESTION;
    } else if ([str isEqualToString:@","]) {
        return TG_CONTINUATION;
    } else if ([str isEqualToString:@";"]) {
        return TG_HALF_PERIOD;
    } else if ([str isEqualToString:@":"]) {
        return TG_CONTINUATION;
    }

    return TG_UNDEFINED;
}

@end
