/*
 *    Filename:	PageNode.m 
 *    Created :	Fri Jun  4 12:22:08 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Fri Jun  4 14:00:12 1993"
 *
 * $Id: PageNode.m,v 1.2 1994/06/03 19:28:24 dale Exp $
 *
 * $Log: PageNode.m,v $
 * Revision 1.2  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.1  1993/06/04  21:01:35  dale
 * Initial revision
 *
 */

#import "PageNode.h"

@implementation PageNode

- init
{
    [super init];
    bookmark = nil;
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
    bookmark = NXReadObject(typedStream);
    return self;
}

- write:(NXTypedStream *)typedStream
{
    [super write:typedStream];
    /* class-specific archiving code */
    NXWriteObject(typedStream, bookmark);
    return self;
}

- setBookmark:bookmarkNode
{
    bookmark = bookmarkNode;
    return self;
}

- bookmark
{
    return bookmark;
}

@end
