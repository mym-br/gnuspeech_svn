/*
 *    Filename:	Node.h 
 *    Created :	Wed May 19 14:36:15 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Fri Jun  4 12:17:18 1993"
 *
 * $Id: Node.h,v 1.5 1994/06/03 19:28:24 dale Exp $
 *
 * $Log: Node.h,v $
 * Revision 1.5  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.4  1993/06/04  20:57:48  dale
 * *** empty log message ***
 *
 * Revision 1.3  1993/05/30  08:24:27  dale
 * *** empty log message ***
 *
 * Revision 1.2  1993/05/27  00:16:28  dale
 * Added set and query methods.
 *
 * Revision 1.1  1993/05/20  06:03:35  dale
 * Initial revision
 *
 */

#import <objc/Object.h>

@interface Node:Object
{
    int start;
    int end;
    int level;                  
}

/* GENERAL METHODS */
- init;
- free;

/* ARCHIVING METHODS */
- awake;
- read:(NXTypedStream *)typedStream;
- write:(NXTypedStream *)typedStream;

/* SET METHODS */
- setStart:(int)aValue;
- setEnd:(int)aValue;
- setLevel:(int)aValue;

/* QUERY METHODS */
- (int)start;
- (int)end;
- (int)length;
- (int)level;

@end
