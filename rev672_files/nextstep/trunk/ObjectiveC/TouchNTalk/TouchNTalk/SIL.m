/*
 *    Filename:	SIL.m 
 *    Created :	Sun May 16 16:46:08 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Tue Jul 26 11:03:25 1994"
 *
 * $Id: SIL.m,v 1.14 1994/07/26 20:11:02 dale Exp $
 *
 * $Log: SIL.m,v $
 * Revision 1.14  1994/07/26  20:11:02  dale
 * *** empty log message ***
 *
 * Revision 1.13  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.12  1993/07/23  07:33:00  dale
 * *** empty log message ***
 *
 * Revision 1.11  1993/07/14  22:11:48  dale
 * *** empty log message ***
 *
 * Revision 1.10  1993/07/06  00:34:26  dale
 * Incorporated SpeakTactileText object.
 *
 * Revision 1.9  1993/07/04  17:57:23  dale
 * *** empty log message ***
 *
 * Revision 1.8  1993/07/01  20:18:47  dale
 * Made SIL horizontally resizable and scrollable.
 *
 * Revision 1.7  1993/06/25  23:38:25  dale
 * Added bookmarkNumber for dealing with default bookmark names.
 *
 * Revision 1.6  1993/06/24  07:40:50  dale
 * Added -setTextNoErase to set the text without erasing all current speech.
 *
 * Revision 1.5  1993/06/05  07:37:08  dale
 * *** empty log message ***
 *
 * Revision 1.4  1993/06/04  07:18:00  dale
 * *** empty log message ***
 *
 * Revision 1.3  1993/05/27  00:16:28  dale
 * No change.
 *
 * Revision 1.2  1993/05/20  19:24:41  dale
 * Added the -display method call to -setText:.
 *
 * Revision 1.1  1993/05/20  06:03:35  dale
 * Initial revision
 *
 */

#import "SILText.h"
#import "SILSpeaker.h"
#import "SIL.h"

@implementation SIL

- initFrame:(NXRect *)frameRect
{
    NXRect rect = *frameRect;
    NXSize maxSize = {1.0E38, rect.size.height - 4.0};   // maximum size of the text object

    [super initFrame:frameRect];

    // Here we set the frameRect which will be used for the minimum page size to be 4.0 less in width
    // and height since this stops the text object from shifting up and down a couple of pixels when 
    // selection occurs. This is mostly for aesthetics.

    rect.size.height -= 4.0;
    rect.size.width -= 4.0;

    // initialize tactileSpeaker to nil
    tactileSpeaker = nil;

    [self setBackgroundGray:NX_LTGRAY];
    [self setBorderType:NX_BEZEL];

    silText = [[SILText alloc] initFrame:&rect text:NULL alignment:NX_LEFTALIGNED];
    [silText setFont:[Font newFont:"Ohlfs" size:12.0]];
    [silText setBackgroundGray:NX_WHITE];
    [silText setOpaque:YES];
    [silText setNoWrap];
    [silText setHorizResizable:YES];
    [silText setEditable:NO];
    [silText setMinSize:&(rect.size)];
    [silText setMaxSize:&maxSize];
    [self setDocView:silText];
    return self;
}

- free
{
    [silText free];
    return [super free];
}

/* Sets the text to the contents of string, displays it, and then speaks it. Before we actually speak
 * the text, we force all current speech to halt. Returns self.
 */
- setText:(const char *)string
{
    [tactileSpeaker eraseAllSound];
    [[silText speaker] eraseAllSound];
    [[[silText setText:string] sizeToFit] speakAll];
    return self;
}

/* Set the SIL to the contents of string and speaks the text. We do NOT erase any current or ongoing
 * speech. Returns self.
 */
- setTextNoErase:(const char *)string
{
    [[[silText setText:string] sizeToFit] speakAll];
    return self;
}

/* Set the SIL to the contents of string and erases ALL tactile speech ONLY. The text is then spoken
 * only after any other messages requiring the SIL to speak text are spoken. Returns self.
 */
- setTextNoEraseSIL:(const char *)string
{
    [tactileSpeaker eraseAllSound];
    [[[silText setText:string] sizeToFit] speakAll];
    return self;
}

/* Sets the SIL to the contents of string, but only displays it. Returns self. */
- setTextNoSpeech:(const char *)string
{
    [[silText setText:string] sizeToFit];
    return self;
}

/* Speaks the current text only, after erasing any current speech. Returns self. */
- setTextNoDisplay:(const char *)string
{
    SILSpeaker *speaker = [silText speaker];

    [tactileSpeaker eraseAllSound];
    [speaker eraseAllSound];
    [speaker speakText:string];
    return self;
}

/* Speaks the text without erasing current or ongoing speech. Returns self. */
- setTextNoDisplayNoErase:(const char *)string
{
    SILSpeaker *speaker = [silText speaker];
    [speaker speakText:string];
    return self;
}

/* This method MUST be called so SIL message will override all active speech. The message 
 * -eraseAllSound must be send to all TTS (or TTS subclass) instances so that the SIL can speak its
 * message immediately, if required. Returns self.
 */
- setTactileSpeaker:aSpeaker
{
    tactileSpeaker = aSpeaker;
    return self;
}

- speaker
{
    return [silText speaker];
}

- silText
{
    return silText;
}

@end
