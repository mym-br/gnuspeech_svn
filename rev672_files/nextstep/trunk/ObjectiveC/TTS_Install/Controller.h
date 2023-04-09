/*
 *    Filename:	Controller.h 
 *    Created :	Mon Jun  1 18:52:27 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *    LastEditDate was "Mon Jun  1 19:39:29 1992"
 *
 *    $Id: Controller.h,v 1.1 2002-03-21 16:49:48 rao Exp $
 *
 *    $Log: not supported by cvs2svn $
 * Revision 1.0  1992/06/09  05:22:41  vince
 * Initial revision
 *
 */


/* Generated by Interface Builder */

#import <objc/Object.h>

@interface Controller:Object
{
    id fontLocationField;
    id serverLocationField;
    id acceptButton;

    char systemPath[1024];
    char fontPath[1024];
}

- setFontLocation:sender;
- accept:sender;
- setServerLocation:sender;
- appDidInit:sender;

@end