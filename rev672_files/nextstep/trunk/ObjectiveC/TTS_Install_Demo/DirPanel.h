/*
 *    Filename:	DirPanel.h 
 *    Created :	Mon Jun  1 18:52:12 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *    LastEditDate was "Mon Jun  1 19:52:09 1992"
 *
 *    $Id: DirPanel.h,v 1.1 2002-03-21 16:49:48 rao Exp $
 *
 *    $Log: not supported by cvs2svn $
 * Revision 1.0  1992/06/09  05:22:41  vince
 * Initial revision
 *
 */

#import <appkit/SavePanel.h>

@interface SavePanel (DirPanel)
	/* Call this routing as opposed to SavePanel's runModalFor. */
-(int)dirPanelRunModal;

@end
