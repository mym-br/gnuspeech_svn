/*
 *    Filename:	NiftyMatrix.h 
 *    Created :	Tue Jan 14 21:48:39 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *
 * LastEditDate "Fri May 22 00:29:05 1992"
 *
 * $Log: not supported by cvs2svn $
 * Revision 1.1  2002/03/21 16:49:47  rao
 * Initial import.
 *
 * Revision 2.1  1992/06/10  14:26:58  vince
 * initFrame method has been removed. and the cache Windows
 * are now global static variables this has been done
 * inorder to have all instances of the NiftyMatrix class share
 * the same two cache windows. This saves a few bytes of memory.
 *
 * Revision 2.0  1992/04/08  03:43:23  vince
 * Initial-Release
 *
 *
 */


// NiftyMatrix.h
// By Jayson Adams, NeXT Developer Support Team
// You may freely copy, distribute and reuse the code in this example.
// NeXT disclaims any warranty of any kind, expressed or implied, as to its
// fitness for any particular use.

#import <AppKit/NSMatrix.h>

/* There are two global variables in the Class nifty_matrixCache and nifty_cellCache
 * The are used for the offscreen buffers
 */
@interface NiftyMatrix:NSMatrix
{
    id  activeCell;
}

/* instance methods */
- (void)dealloc;
- (void)mouseDown:(NSEvent *)theEvent;
- (void)drawRect:(NSRect)rects;
- (void)setupCacheWindows;
- sizeCacheWindow:cacheWindow to:(NSSize)windowSize;

@end
