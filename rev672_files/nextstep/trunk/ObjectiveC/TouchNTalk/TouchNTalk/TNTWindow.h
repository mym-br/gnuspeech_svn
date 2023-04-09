/*
 *    Filename:	TNTWindow.h 
 *    Created :	Thu Aug 26 13:21:11 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Thu Aug 26 21:26:49 1993"
 *
 * $Id: TNTWindow.h,v 1.3 1994/06/03 19:28:24 dale Exp $
 *
 * $Log: TNTWindow.h,v $
 * Revision 1.3  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.2  1993/08/27  08:08:08  dale
 * *** empty log message ***
 *
 * Revision 1.1  1993/08/27  03:51:06  dale
 * Initial revision
 *
 */

#import <appkit/appkit.h>

@interface Window (TNTWindow)

- (BOOL)canBecomeKeyWindow;

@end
