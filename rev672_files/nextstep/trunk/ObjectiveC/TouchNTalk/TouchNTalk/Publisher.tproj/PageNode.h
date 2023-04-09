/*
 *    Filename:	PageNode.h 
 *    Created :	Fri Jun  4 12:16:32 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Fri Jun  4 14:00:28 1993"
 *
 * $Id: PageNode.h,v 1.2 1994/06/03 19:28:24 dale Exp $
 *
 * $Log: PageNode.h,v $
 * Revision 1.2  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.1  1993/06/04  21:01:35  dale
 * Initial revision
 *
 */

#import <objc/Object.h>
#import "Node.h"

@interface PageNode:Node
{
    id bookmark;   // holds the bookmark node corresponding to this page node
}

/* GENERAL METHODS */
- init;
- free;

/* ARCHIVING METHODS */
- awake;
- read:(NXTypedStream *)typedStream;
- write:(NXTypedStream *)typedStream;

/* SET METHODS */
- setBookmark:bookmarkNode;

/* QUERY METHODS */
- bookmark;

@end
