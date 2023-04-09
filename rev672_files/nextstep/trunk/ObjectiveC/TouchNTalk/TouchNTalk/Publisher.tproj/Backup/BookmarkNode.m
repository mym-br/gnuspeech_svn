/*
 *    Filename:	BookmarkNode.m 
 *    Created :	Sat May 29 22:42:12 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Fri Jun  4 11:55:29 1993"
 *
 * $Id: BookmarkNode.m,v 1.5 1994/06/03 19:28:24 dale Exp $
 *
 * $Log: BookmarkNode.m,v $
 * Revision 1.5  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.4  1993/06/04  20:57:48  dale
 * *** empty log message ***
 *
 * Revision 1.3  1993/06/04  07:18:00  dale
 * *** empty log message ***
 *
 * Revision 1.2  1993/06/01  08:03:24  dale
 * *** empty log message ***
 *
 * Revision 1.1  1993/05/30  08:24:27  dale
 * Initial revision
 *
 */

#import "BookmarkNode.h"

@implementation BookmarkNode

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
    NXReadArray(typedStream, "c", 256, &name);
    NXReadTypes(typedStream, "i", &pageNumber);
    return self;
}

- write:(NXTypedStream *)typedStream
{
    [super write:typedStream];
    /* class-specific archiving code */
    NXWriteArray(typedStream, "c", 256, name);
    NXWriteTypes(typedStream, "i", &pageNumber);
    return self;
}

/* Sets the bookmark name by making a local COPY of the NULL terminated name string. Bookmark names 
 * must be less than 256 characters. Returns self.
 */
- setName:(const char *)bookmarkName
{
    strcpy(name, bookmarkName);
    return self;
}

- setPageNumber:(int)pageNum
{
    pageNumber = pageNum;
    return self;
}

- (const char *)name
{
    return name;
}

- (int)pageNumber
{
    return pageNumber;
}

@end
