/*
 *    Filename:	SpeakText.m 
 *    Created :	Thu May 13 12:16:25 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Fri Jul 16 22:46:15 1993"
 *
 * All -speakSelection... methods examine the status of the speechMode instance variable to determine
 * if they should infact speak or spell out the selected text. These are the only methods that make 
 * use of the speechMode instance variable.
 *
 * $Id: SpeakText.m,v 1.10 1994/06/03 19:28:24 dale Exp $
 *
 * $Log: SpeakText.m,v $
 * Revision 1.10  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.9  1993/07/23  07:33:00  dale
 * *** empty log message ***
 *
 * Revision 1.8  1993/07/14  22:11:48  dale
 * *** empty log message ***
 *
 * Revision 1.7  1993/07/06  00:34:26  dale
 * Utilizes TextToSpeech instance (new connection) each time created.
 *
 * Revision 1.6  1993/06/24  07:40:50  dale
 * *** empty log message ***
 *
 * Revision 1.5  1993/06/05  07:37:08  dale
 * *** empty log message ***
 *
 * Revision 1.4  1993/06/03  00:37:58  dale
 * *** empty log message ***
 *
 * Revision 1.3  1993/05/30  08:24:27  dale
 * *** empty log message ***
 *
 * Revision 1.2  1993/05/27  00:16:28  dale
 * Fixed -speakAll method to properly speak text.
 *
 * Revision 1.1  1993/05/20  06:03:35  dale
 * Initial revision
 *
 */

#import <TextToSpeech/TextToSpeech.h>
#import "SpeakText.h"

@implementation SpeakText

/* This method is the designated initializer for the class. We create a connection to the TTS Server
 * in speaker by instantiating a TTS class instance. The speech mode is also initialized to the 
 * default ST_SPEAK mode. Returns self.
 */
- initFrame:(const NXRect *)frameRect text:(const char *)theText alignment:(int)mode
{
    [super initFrame:frameRect text:theText alignment:mode];
    if ((speaker = [[TextToSpeech alloc] init]) == nil) {
	NXBeep();
	NXRunAlertPanel("TextToSpeech Server", "Too many clients, or server cannot be started.", 
			"OK", NULL, NULL);
	[NXApp terminate:self];
    }
    speechMode = ST_SPEAK;   // default speechMode
    return self;
}

- initFrame:(const NXRect *)frameRect
{
    return [self initFrame:frameRect text:NULL alignment:NX_LEFTALIGNED];
}

- free
{
    [speaker free];
    return [super free];
}

/* Speaks the current selection. If there is no text highlighted, then emit a beep. We either speak or
 * spell the selection based on the value of speechMode. Returns self.
 */
- speakSelection
{
    char *buffer = NULL;   // buffer containing text to be spoken
    int count;             // number of characters in selection

    if ((count = [self selectionCharacterCount]) > 0) {
	if (speechMode == ST_SPEAK) {
	    buffer = malloc(sizeof(char) * count + 1);
	    [self readCharactersFromSelection:buffer count:count];
	    buffer[count] = (char)0;
	} else if (speechMode == ST_SPELL) {
	    buffer = malloc(sizeof(char) * count + 7);
	    buffer[0] = [speaker escapeCharacter];
	    buffer[1] = 'l';
	    buffer[2] = 'b';
	    [self readCharactersFromSelection:&buffer[3] count:count];
	    buffer[count+3] = buffer[0];
	    buffer[count+4] = 'l';
	    buffer[count+5] = 'e';
	    buffer[count+6] = '\0';
	}
	[speaker speakText:buffer];
	free(buffer);
    } else {
	NXBeep();
    }
    return self;
}

/* Speaks a NULL terminated buffer of text. Returns self. */
- speakText:(const char *)buffer
{
    if (speechMode == ST_SPEAK) {
	[speaker speakText:buffer];
    } else if (speechMode == ST_SPELL) {
	[self spellText:buffer ofSize:strlen(buffer)];
    }
    return self;
}

/* Spells out a NULL terminated buffer of text. We search sequentially through the array in order to 
 * find the location of the NULL termination character. Use -spellText:ofSize: if the size of the 
 * buffer is already known. Returns self.
 */
- spellText:(const char *)buffer
{
    char *newBuffer;
    int  i;

    for (i = 0; buffer[i] != '\0'; i++)
       ;
    newBuffer = malloc(sizeof(char) * i + 7);
    newBuffer[0] = [speaker escapeCharacter];
    newBuffer[1] = 'l';
    newBuffer[2] = 'b';
    bcopy(buffer, &newBuffer[3], i);
    newBuffer[i+3] = newBuffer[0];
    newBuffer[i+4] = 'l';
    newBuffer[i+5] = 'e';
    newBuffer[i+6] = '\0';
    [speaker speakText:newBuffer];
    free(newBuffer);
    return self;
}

/* Same as -spellText: except does not have to search for the NULL termination character, and is
 * therefore much faster. Assumes the size of the buffer does NOT include a NULL termination 
 * character. Returns self.
 */
- spellText:(const char *)buffer ofSize:(int)size
{
    char *newBuffer;

    newBuffer = malloc(sizeof(char) * size + 7);
    newBuffer[0] = [speaker escapeCharacter];
    newBuffer[1] = 'l';
    newBuffer[2] = 'b';
    bcopy(buffer, &newBuffer[3], size);
    newBuffer[size+3] = newBuffer[0];
    newBuffer[size+4] = 'l';
    newBuffer[size+5] = 'e';
    newBuffer[size+6] = '\0';
    [speaker speakText:newBuffer];
    free(newBuffer);
    return self;
}

/* Speak all text that we hold. Note that we must reset the stream position each time the method is 
 * called since NXReadOnlyTextStream methods apply to the current position of the stream. Also note
 * that textLength is one greater than the ACTUAL number of characters. We speak or spell the text
 * depending on the current setting of the speech mode. Returns self.
 */
- speakAll
{
    char *buffer;

    if (textLength > 0) {
	buffer = malloc(sizeof(char) * textLength);
	[self seekToCharacterAt:0 relativeTo:NX_StreamStart];
	[self readCharacters:buffer count:textLength];
	buffer[textLength-1] = (char)0;
	if (speechMode == ST_SPEAK) {
	    [speaker speakText:buffer];
	} else if (speechMode == ST_SPELL) {
	    [self spellText:buffer ofSize:textLength-1];
	}
	free(buffer);
    }
    return self;
}

/* Responder method which speaks the highlighted text. Functionally equivalent to -speakSelection.
 * Returns self.
 */
- speakSelection:sender
{
    return [self speakSelection];
}

/* Responder method which speaks all text. Functionally equivalent to -speakAll. Returns self. */
- speakAll:sender
{
    return [self speakAll];
}

- setSpeaker:theSpeaker
{
    speaker = theSpeaker;
    return self;
}

/* Possible modes include ST_SPEAK and ST_SPELL. If an invalid value is passed, we default to
 * ST_SPEAK. Return self.
 */
- setSpeechMode:(int)mode
{
    if (mode < ST_SPEAK || mode > ST_SPELL) {   // invalid mode
	speechMode = ST_SPEAK;
    } else {   // valid mode
	speechMode = mode;
    }
    return self;
}

/* Returns the speaker object which is an instance of the TTS class. */
- speaker
{
    return (id)speaker;
}

/* Returns the value of speechMode. Possible values include ST_SPELL, and ST_SPEAK. */
- (int)speechMode
{
    return speechMode;
}

@end
