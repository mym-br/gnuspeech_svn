/*
 *    Filename : CanvasView.h 
 *    Created  : Tue Jan 17 21:36:26 1995 
 *    Author   : Dale Brisinda
 *		 <dale@localhost>
 *
 *    Last modified on "Fri Jan 20 20:27:18 1995"
 *    Copyright (c) 1995, Dale Brisinda. All rights reserved.
 *
 * $Id: CanvasView.h,v 1.2 1995/01/21 04:01:26 dale Exp $
 *
 * $Log: CanvasView.h,v $
 * Revision 1.2  1995/01/21 04:01:26  dale
 * Added support for choice of cursors while drawing.
 *
 * Revision 1.1  1995/01/20  11:42:00  dale
 * Initial revision
 *
 */

@class NXImage;

#import <appkit/appkit.h>

@interface CanvasView:View
{
    id image;                 // display image
    id imageCopy;             // copy of display image
    id cursor;                // cursor image 

    float lineWidth;          // line width
    NXColor lineColor;        // line color

    BOOL shouldUpdateImage;   // should we update the image (and composite)?
    BOOL copyPSCode;          // are we copying PS code?

    NXRect lastBounds;        // last view bounds rectangle
    NXRect maxBounds;         // max view bounds rectangle encountered
    NXEvent lastEvent;        // the last (previous) event
}

/* INITIALIZING AND FREEING */
- initFrame:(NXRect *)frameRect;
- free;
- awakeFromNib;

/* WINDOW RESIZE NOTIFICATION */
- windowWillResize;
- windowDidResize;

/* TABLET EVENT TRACKING */
- trackEvent:(NXEvent *)theEvent;

/* DRAWING */
- drawSelf:(const NXRect *)rects :(int)rectCount;
- drawLine:(NXPoint *)point1 :(NXPoint *)point2;
- copyPSCodeInside:(const NXRect *)rect to:(NXStream *)stream;

/* CLEARING THE VIEW */
- clear;

/* SET METHODS */
- setLineWidth:(float)width;
- setLineColor:(NXColor)color;
- setImage:(NXImage *)anImage;
- setCursor:(const char *)imageName;

/* QUERY METHODS */
- (NXImage *)image;

@end
