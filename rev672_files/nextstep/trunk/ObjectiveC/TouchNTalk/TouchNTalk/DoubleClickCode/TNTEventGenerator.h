/*
 *    Filename:	TNTEventGenerator.h 
 *    Created :	Thu Aug 19 22:27:16 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Fri Jun 10 01:30:15 1994"
 *
 * $Id: TNTEventGenerator.h,v 1.3 1994/06/03 19:28:24 dale Exp $
 *
 * $Log: TNTEventGenerator.h,v $
 * Revision 1.3  1994/06/03  19:28:24  dale
 * Fixed problem where dragging of stylus caused no events to be processed. Also changed
 * "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.2  1993/09/04  17:49:22  dale
 * Added event posting, and finished velocity, and direction.
 *
 * Revision 1.1  1993/08/24  02:08:33  dale
 * Initial revision
 *
 */

#import <appkit/appkit.h>

@interface TNTEventGenerator:Object
{
    NXEvent prevEvent;           // previous tablet kit event
    NXEvent prevTTEvent;         // previous TouchNTalk event
    DPSTimedEntry postEventTE;   // delay event post timed-entry
    NXEventHandle eventHandle;   // handle to event status driver
    NXSize clickSpaceThresh;     // holds contents of NXGetClickSpace() call
}

/* INITIALIZING */
- init;

/* EVENT GENERATION */
- generateEvent:(const NXEvent *)theEvent;

/* UTILITY METHODS */
- (short)stylusClicks:(const NXEvent *)currEvent;
- (short)stylusDirection:(const NXEvent *)currEvent;
- (short)stylusVelocity:(const NXEvent *)currEvent;

@end
