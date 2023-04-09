/*
 *    Filename:	SIL.h 
 *    Created :	Sun May 16 16:46:05 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Wed Jul 14 16:02:27 1993"
 *
 * $Id: SIL.h,v 1.12 1994/06/03 19:28:24 dale Exp $
 *
 * $Log: SIL.h,v $
 * Revision 1.12  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.11  1993/07/23  07:33:00  dale
 * *** empty log message ***
 *
 * Revision 1.10  1993/07/14  22:11:48  dale
 * *** empty log message ***
 *
 * Revision 1.9  1993/07/06  00:34:26  dale
 * Incorporated SpeakTactileText object.
 *
 * Revision 1.8  1993/07/04  17:57:23  dale
 * *** empty log message ***
 *
 * Revision 1.7  1993/07/01  20:18:47  dale
 * Made SIL horizontally resizable and scrollable.
 *
 * Revision 1.6  1993/06/25  23:38:25  dale
 * Added bookmarkNumber for dealing with default bookmark names.
 *
 * Revision 1.5  1993/06/24  07:40:50  dale
 * Added -setTextNoErase to set the text without erasing all current speech.
 *
 * Revision 1.4  1993/06/05  07:37:08  dale
 * *** empty log message ***
 *
 * Revision 1.3  1993/06/04  07:18:00  dale
 * *** empty log message ***
 *
 * Revision 1.2  1993/05/27  00:16:28  dale
 * No change.
 *
 * Revision 1.1  1993/05/20  06:03:35  dale
 * Initial revision
 *
 */

#import <appkit/appkit.h>

@interface SIL:ScrollView
{
    id silText;
    id tactileSpeaker;
}

/* GENERAL METHODS */
- initFrame:(NXRect *)frameRect;
- free;

/* SYSTEM INTERACTION METHODS */
- setText:(const char *)string;
- setTextNoErase:(const char *)string;
- setTextNoEraseSIL:(const char *)string;
- setTextNoSpeech:(const char *)string;
- setTextNoDisplay:(const char *)string;
- setTextNoDisplayNoErase:(const char *)string;

/* SET METHODS */
- setTactileSpeaker:aSpeaker;

/* QUERY METHODS */
- speaker;
- silText;

@end
