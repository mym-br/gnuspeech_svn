/*
 *    Filename:	BookmarkNode.h 
 *    Created :	Sat May 29 22:39:47 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Fri Jun 25 16:09:57 1993"
 *
 * $Id: BookmarkNode.h,v 1.6 1994/06/03 19:28:24 dale Exp $
 *
 * $Log: BookmarkNode.h,v $
 * Revision 1.6  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.5  1993/06/25  23:38:25  dale
 * *** empty log message ***
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

#import <objc/Object.h>

@interface BookmarkNode:Object
{
    char name[256];   // holds the name of the bookmark
    int pageNumber;   // holds the page number of the bookmark
}

/* GENERAL METHODS */
- init;
- free;

/* ARCHIVING METHODS */
- awake;
- read:(NXTypedStream *)typedStream;
- write:(NXTypedStream *)typedStream;

/* SET METHODS */
- setName:(const char *)name;
- setPageNumber:(int)pageNum;

/* QUERY METHODS */
- (const char *)name;
- (int)pageNumber;

@end
