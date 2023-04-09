/*
 *    Filename:	TNTWindow.m 
 *    Created :	Thu Aug 26 13:22:12 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Tue Jul 26 11:06:57 1994"
 *
 * $Id: TNTWindow.m,v 1.3 1994/07/26 20:11:02 dale Exp $
 *
 * $Log: TNTWindow.m,v $
 * Revision 1.3  1994/07/26  20:11:02  dale
 * *** empty log message ***
 *
 * Revision 1.2  1994/06/03  19:28:24  dale
 * Changed "LastEditDate" to "Last modified on" within header.
 *
 * Revision 1.1  1993/08/27  03:51:06  dale
 * Initial revision
 *
 */

#import "TouchNTalk.h"
#import "TNTControl.h"
#import "TNTWindow.h"

@implementation Window (TNTWindow)

- (BOOL)canBecomeKeyWindow
{
    if ([delegate isKindOf:[TNTControl class]]) {   // TNT control window
	if ([[NXApp delegate] configuringTablet]) {
	    return NO;
	} else {
	    return YES;
	}
    } else if ([self isKindOf:[Menu class]]) {   // menus can't become key
	return NO;
    } else {
	return YES;
    }
}

@end
