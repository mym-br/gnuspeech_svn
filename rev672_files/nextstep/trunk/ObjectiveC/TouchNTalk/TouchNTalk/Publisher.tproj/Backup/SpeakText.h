/*
 *    Filename:	SpeakText.h 
 *    Created :	Thu May 13 12:05:54 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Sun Jul 11 12:15:32 1993"
 *
 * $Id: SpeakText.h,v 1.6 1994/06/03 19:28:24 dale Exp $
 *
 * $Log: SpeakText.h,v $
 * Revision 1.6  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.5  1993/07/14  22:11:48  dale
 * *** empty log message ***
 *
 * Revision 1.4  1993/07/06  00:34:26  dale
 * Utilizes TextToSpeech instance (new connection) each time created.
 *
 * Revision 1.3  1993/06/05  07:37:08  dale
 * *** empty log message ***
 *
 * Revision 1.2  1993/05/30  08:24:27  dale
 * *** empty log message ***
 *
 * Revision 1.1  1993/05/20  06:03:35  dale
 * Initial revision
 *
 */

@class TextToSpeech;

/* SpeakText speech modes. */
#define ST_SPEAK 0
#define ST_SPELL 1

#import <appkit/appkit.h>

@interface SpeakText:Text
{
    TextToSpeech *speaker;   // TextToSpeech instance
    int speechMode;          // speak or spell mode?
}

/* GENERAL METHODS */
- initFrame:(const NXRect *)frameRect text:(const char *)theText alignment:(int)mode;
- initFrame:(const NXRect *)frameRect;
- free;

/* SPEECH METHODS */
- speakSelection;
- speakText:(const char *)buffer;
- speakAll;

/* PRIVATE METHODS */
- spellText:(const char *)buffer;
- spellText:(const char *)buffer ofSize:(int)size;

/* RESPONDER METHODS */
- speakSelection:sender;
- speakAll:sender;

/* SET METHODS */
- setSpeaker:theSpeaker;
- setSpeechMode:(int)mode;

/* QUERY METHODS */
- speaker;
- (int)speechMode;

@end
