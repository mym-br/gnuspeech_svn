/*
 *    Filename:	TNTEvent.h 
 *    Created :	Thu Aug 19 00:45:19 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Thu Aug 19 23:23:53 1993"
 *
 * $Id: TNTEvent.h,v 1.2 1994/06/03 19:28:24 dale Exp $
 *
 * $Log: TNTEvent.h,v $
 * Revision 1.2  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.1  1993/08/24  02:08:33  dale
 * Initial revision
 *
 */

#import <objc/Object.h>

@interface TNTEvent:Object
{
    NXPoint location;   // location of stylus
    short direction;    // direction of stylus in degrees (0 to 359)
    short velocity;     // velocity of stylus (delta previous location)
    short clicks;       // number of stylus clicks
    long time;          // timestamp
    id region;          // region of stylus
    id groove;          // groove within region
}

/* EVENT QUERY METHODS */
- (NXPoint)location;
- (short)direction;
- (short)velocity;
- (short)clicks;
- (long)time;
- region;
- groove;

/* EVENT SET METHODS */
- setLocation:(NXPoint *)theLocation;
- setDirection:(short)theDirection;
- setVelocity:(short)theVelocity;
- setClicks:(short)theClicks;
- setTime:(long)theTime;
- setRegion:theRegion;
- setGroove:theGroove;

@end
