/*
 *    Filename:	SILText.h 
 *    Created :	Sun Jul  4 13:54:01 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Tue Jul 26 11:21:00 1994"
 *
 * $Id: SILText.h,v 1.4 1994/07/26 20:11:02 dale Exp $
 *
 * $Log: SILText.h,v $
 * Revision 1.4  1994/07/26  20:11:02  dale
 * *** empty log message ***
 *
 * Revision 1.3  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.2  1993/07/23  07:33:00  dale
 * *** empty log message ***
 *
 * Revision 1.1  1993/07/14  22:11:48  dale
 * Initial revision
 *
 * Revision 1.1  1993/07/06  00:34:26  dale
 * Initial revision
 *
 */

#import <appkit/appkit.h>
#import "Publisher.tproj.h"

@interface SILText:ActionText
{
}

/* INITIALIZATION METHODS */
- initFrame:(const NXRect *)frameRect text:(const char *)theText alignment:(int)mode;

/* OVERRIDEN CURSOR RELATED METHODS */
- convertPoint:(NXPoint *)aPoint toLine:(int *)line col:(int *)col;

@end
