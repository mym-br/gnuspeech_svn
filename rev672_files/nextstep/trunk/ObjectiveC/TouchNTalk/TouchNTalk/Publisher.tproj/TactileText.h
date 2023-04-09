/*
 *    Filename:	TactileText.h 
 *    Created :	Mon Jul  5 00:11:55 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Sun Jul 11 22:15:04 1993"
 *
 * $Id: TactileText.h,v 1.2 1994/06/03 19:28:24 dale Exp $
 *
 * $Log: TactileText.h,v $
 * Revision 1.2  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.1  1993/07/14  22:11:48  dale
 * Initial revision
 *
 * Revision 1.1  1993/07/06  00:34:26  dale
 * Initial revision
 *
 */

#import <appkit/appkit.h>
#import "ActionText.h"

@interface TactileText:ActionText
{
}

/* INITIALIZATION METHODS */
- initFrame:(const NXRect *)frameRect text:(const char *)theText alignment:(int)mode;

@end
