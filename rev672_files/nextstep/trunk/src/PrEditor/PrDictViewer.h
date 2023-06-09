/*
 *    Filename:	PrDictViewer.h 
 *    Created :	Mon May  4 23:23:32 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *    LastEditDate was "Wed May 27 00:10:16 1992"
 *
 *    $Id: PrDictViewer.h,v 1.1 2002-03-21 16:49:51 rao Exp $
 *
 *    $Log: not supported by cvs2svn $
 * Revision 2.1  1992/06/10  14:24:04  vince
 * *** empty log message ***
 *
 */


/* Generated by Interface Builder */

#import <objc/Object.h>
#import <appkit/graphics.h> // For NXRect
/* #import <zone.h> Don't need this as it is included by objc/Object.h already */

@interface PrDictViewer:Object
{
    NXRect          viewerRect;
    
    id              browser;
    id              viewerPanel;
    id              prDictionary;
}

- init;
- documentChanged;

- loadDict:dictionary;

- dictViewer:sender;

- browserHit:sender;
- browserDoubleHit:sender;

/* Browser Delegation methods */
- (int)browser:sender getNumRowsInColumn:(int)column;
- browser:sender loadCell:cell atRow:(int)row inColumn:(int)column;

/* Window Delegation methods */
- windowWillResize:sender toSize:(NXSize *)frameSize;
- windowDidUpdate:sender;
@end
