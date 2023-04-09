/*
 *    Filename:	TNTEvent.m 
 *    Created :	Thu Aug 19 22:52:54 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Thu Aug 19 23:23:41 1993"
 *
 * $Id: TNTEvent.m,v 1.2 1994/06/03 19:28:24 dale Exp $
 *
 * $Log: TNTEvent.m,v $
 * Revision 1.2  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.1  1993/08/24  02:08:33  dale
 * Initial revision
 *
 */

#import "TNTEvent.h"

@implementation

/* EVENT QUERY METHODS ******************************************************************************/

- (NXPoint)location
{
    return location;
}

- (short)direction
{
    return direction;
}

- (short)velocity
{
    return velocity;
}

- (short)clicks
{
    return clicks;
}

- (long)time
{
    return time;
}

- region
{
    return region;
}

- groove
{
    return groove;
}


/* EVENT SET METHODS ********************************************************************************/


- setLocation:(NXPoint *)theLocation
{
    location = *theLocation;
    return self;
}

- setDirection:(short)theDirection
{
    direction = theDirection;
    return self;
}

- setVelocity:(short)theVelocity
{
    velocity = theVelocity;
    return self;
}

- setClicks:(short)theClicks
{
    clicks = theClicks;
    return self;
}

- setTime:(long)theTime
{
    time = theTime;
    return self;
}

- setRegion:theRegion
{
    region = theRegion;
    return self;
}

- setGroove:theGroove
{
    groove = theGroove;
    return self;
}

@end
