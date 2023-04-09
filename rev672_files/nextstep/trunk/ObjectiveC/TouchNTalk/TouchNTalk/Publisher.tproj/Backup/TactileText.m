/*
 *    Filename:	TactileText.m 
 *    Created :	Mon Jul  5 00:12:18 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Tue Jul 13 15:40:52 1993"
 *
 * $Id: TactileText.m,v 1.2 1994/06/03 19:28:24 dale Exp $
 *
 * $Log: TactileText.m,v $
 * Revision 1.2  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.1  1993/07/14  22:11:48  dale
 * Initial revision
 *
 * Revision 1.1  1993/07/06  00:34:26  dale
 * Initial revision
 *
 */

#import "TNTDefinitions.h"
#import "TactileText.h"
#import "TactileSpeaker.h"

@implementation TactileText

/* This method is the designated initializer for the class. The default connection made to the TTS
 * Server by the message to super is freed since it is not a shared instance. We then create a shared
 * tactile display speaker instance of the TTS Kit through the DisplaySpeaker subclass. We finally
 * initialize the charWidth instance variable to correspond to the width of the default font. Returns
 * self.
 */
- initFrame:(const NXRect *)frameRect text:(const char *)theText alignment:(int)mode
{
    id font = [Font newFont:TNT_DEFAULT_FONT size:TNT_DEFAULT_FONT_SIZE];

    [super initFrame:frameRect text:theText alignment:mode];
    [speaker free];   // free TTS instance created; we want a shared tactile display speaker instance
    speaker = [TactileSpeaker new];

    // char width initialization
    charWidth = (int)ceil((double)[font getWidthOf:"O"]);
    return self;
}

@end
