/*
 *    Filename:	Speech.m 
 *    Created :	Thu Apr  2 18:58:11 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *    LastEditDate was "Tue Jun  9 01:06:53 1992"
 *
 * $Log: not supported by cvs2svn $
# Revision 2.2  92/07/09  11:15:37  len
# Changed literal mode to raw mode.
# Changed raw mode entry so that the pronunciation is fully marked
# as follows:  /c // /0 pronunciation // /c
# Changed escapechars routine so that single quote is converted
# to /*, and double quote to /".
# 
# Revision 2.1  1992/06/10  14:30:32  vince
# This class has been removed and made into a Category of
# the TextToSpeech Object instead. I didn't need to
# subclass TextToSpeech, becuase i really didn't need to
# overide any of it's classes.
#
# Revision 2.0  1992/04/08  03:43:23  vince
# Initial-Release
#
 *
 */

#import "Speech.h"
#import <TextToSpeech/TextToSpeechPron.h>

#import <stdlib.h>
#import <stdio.h>
#import <strings.h>
#import <appkit/Panel.h>
#import <appkit/publicWraps.h>

#import "conversion.h"
#import "objc-debug.h"


#define ESC            '\033'           /* Escape sequence for speakText: method in TextToSpeech Object */
#define START_MODE     "RB"             /* Character sequence for start of Raw mode */
#define END_MODE       "RE"             /* Character sequence for end of Raw mode */

#define PASSWD         (int)0xdeafbabe  /* Passwd for pronunciation method in TextToSpeech Object */


@implementation TextToSpeech(Speech) 

- (int)setDictOrder: (const short int *)order
{
    short int neworder[4] = {TTS_EMPTY,TTS_EMPTY,TTS_EMPTY,TTS_EMPTY};
/* Spec says that the last
 * elements in the search order
 * must be TTS_EMPTY
 */
    int i,j;

    DEBUG_METHOD;

    if (order){
	for (i=0,j=0;i < 4;i++){
	    if ((order[i] >= TTS_NUMBER_PARSER) && (order[i] <= TTS_LETTER_TO_SOUND)){
		neworder[j++] = order[i];
	    }
	}
#ifdef DEBUG
	fprintf(stderr,"setDictOrder: set order to %d %d %d %d\n",
		neworder[0],neworder[1],neworder[2],neworder[3]);
#endif
	
	return [self setDictionaryOrder: (const short int *)neworder];
    }
    return TTS_OUT_OF_RANGE;
}



static inline void escapechars(const char *inputstr,char *escaped)
{
    int length = strlen(inputstr);
    int i, j;

    for (i = 0, j = 0; i <= length; i++) {
	switch(inputstr[i]){
	case 0140:                   // Back Quote `
	case 047:
		escaped[j++] = '/';  // Escape the ' and the ` character as /*
		escaped[j++] = '*'; 
		break;
	case 042:
		escaped[j++] = '/';  // Escape the " character as /"
		escaped[j++] = '"'; 
		break;
	default:
	    escaped[j++] = inputstr[i]; 
	    break;
	}
    }
}



static inline int parse(const char *inputstr)
{
    int length = strlen(inputstr);
    int i;

    for (i=0;i<length;i++){
	switch (inputstr[i]){
	 case 047:
	 case 042:
	    if (i == 0)
		break;
	    else
		if ((inputstr[i-1] == '.') && (inputstr[i+1] != '\000'))
		    break;
		else
		    return -(i+1);
	    break;
	 case '.':
	    if (i == 0)
		return -(i+1);	    
	    else
		if ((inputstr[i-1] == '.') || (inputstr[i+1] == '\000') || 
		    (inputstr[i-1] == 047) || (inputstr[i-1] == 042))
		    return -(i+1);	    
		else
		    break;
	    break;
	 default:
	    break;
	}
    }
    return 0;
}



- (int)speakLiteralMode:(const char *)string
{
    char inputword[2048];
    char fixedword[2048];
    int  parse_val;
    tts_error_t  ret_val;

    DEBUG_METHOD;

    if (string) {
	if ((parse_val = parse(string)) < 0)
	    return parse_val;

	sprintf(inputword,"%c%s/c // /0 /w /l # /_%s # // /c%c%s",
		ESC, START_MODE, PreditorToTTS(string), ESC, END_MODE);
	escapechars(inputword, fixedword);

#ifdef DEBUG
	fprintf(stderr,"speakLiteralMode: sent %s to server\n",fixedword);
#endif

	switch (ret_val = [self speakText:fixedword]) {
	  case TTS_DSP_TOO_SLOW:
	    NXBeep();
	    /*  TELL THE USER THAT THE DSP IS TOO SLOW  */
	    NXRunAlertPanel("DSP hardware is too slow",
	        "Choose a larger voice type and/or a longer vocal tract length offset.",
		"OK", NULL, NULL);
	    return ret_val;
	  case TTS_OK:
	    return ret_val;
	  case TTS_SERVER_HUNG:
	    return ret_val;
	  case TTS_SERVER_RESTARTED:
	    return TTS_OK;
	}
    }

    return TTS_PARSE_ERROR;
}



- (const char *)getPronunciation:(const char *)word dict:(short int *)dictionary
{
    const char *result;
    short int dict;

    DEBUG_METHOD;

    if (word) {
	result = [self pronunciation: word : (dictionary ? dictionary : &dict) : PASSWD];

#ifdef DEBUG
	fprintf(stderr,"getPronunciation: got word %s dictionary %d from server\n",
		result,*dictionary);
#endif

	return (const char *)TTSToPreditor(result); 
    }

    return NULL;
}

@end
