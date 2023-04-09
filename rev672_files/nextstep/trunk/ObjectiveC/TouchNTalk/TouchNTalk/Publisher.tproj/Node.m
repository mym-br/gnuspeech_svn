/*
 *    Filename:	Node.m 
 *    Created :	Wed May 19 14:36:23 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Fri May 21 15:24:41 1993"
 *
 * $Id: Node.m,v 1.3 1994/06/03 19:28:24 dale Exp $
 *
 * $Log: Node.m,v $
 * Revision 1.3  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.2  1993/05/27  00:16:28  dale
 * Added set and query methods.
 *
 * Revision 1.1  1993/05/20  06:03:35  dale
 * Initial revision
 *
 */

#import "Node.h"

@implementation Node

- init
{
    [super init];
    return self;
}

- free
{
    return [super free];
}

- awake
{
    [super awake];
    /* class-specific initialization */
    return self;
}

- read:(NXTypedStream *)typedStream
{
    [super read:typedStream];
    /* class-specific unarchiving code */
    NXReadTypes(typedStream, "iii", &start, &end, &level);
    return self;
}

- write:(NXTypedStream *)typedStream
{
    [super write:typedStream];
    /* class-specific archiving code */
    NXWriteTypes(typedStream, "iii", &start, &end, &level);
    return self;
}

/* These methods set various instance variables. All methods return self. */

- setStart:(int)aValue
{
    start = aValue;
    return self;
}

- setEnd:(int)aValue
{
    end = aValue;
    return self;
}

- setLevel:(int)aValue
{
    level = aValue;
    return self;
}

/* These methods return the value for various instance variables, and other information that can be
 * deduced from the values of the existing instance variables.
 */

- (int)start
{
    return start;
}

- (int)end
{
    return end;
}

- (int)length
{
    return (end - start + 1);
}

- (int)level
{
    return level;
}

@end
