/*
 *    Filename:	Speech.h 
 *    Created :	Thu Apr  2 18:58:15 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *    LastEditDate was "Sat May 16 16:57:54 1992"
 *
 * $Log: not supported by cvs2svn $
 * Revision 2.1  1992/06/10  14:30:32  vince
 * This class has been removed and made into a Category of
 * the TextToSpeech Object instead. I didn't need to
 * subclass TextToSpeech, becuase i really didn't need to
 * overide any of it's classes.
 *
 * Revision 2.0  1992/04/08  03:43:23  vince
 * Initial-Release
 *
 *
 */


#import <TextToSpeech/TextToSpeech.h>

@interface TextToSpeech(Speech) 

/* Set the dictionary order, things out of the range TTS_LETTER_TO_SOUND <= val <= TTS_NUMBER_PARSER
 * Are ignored, this is in contrast to setDictionaryOrder in the TextToSpeech Object itself
 * which will return an error message TTS_OUT_OF_RANGE.
 */
- (int)setDictOrder: (const short int *)order;

/*
 * say the text string in litteral mode, (or is that raw mode) 
 */
- (int)speakLiteralMode:(const char *)string;

/* getPronunciation:dict: 
 * 
 * CAN ONLY BE CALLED SEQUENTUALLY, THE RETURN VALUE IS A STATIC VARIABLE
 * THEREFORE IF YOU NEED THE RETURN VALUE FOR SOME REASON, COPY IT TO SOME LOCAL
 * STORAGE BECAUSE THE NEXT TIME YOU CALL getPronunciation:dict: IT WILL BE GONE
 *
 * If dictionary is a NULL, this call will still work, and obviously nothing will
 * get set.
 */
- (const char *) getPronunciation: (const char *)word dict: (short int *)dictionary;

@end
