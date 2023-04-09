/*
 *    Filename : CanvasView.m 
 *    Created  : Tue Jan 17 21:36:31 1995 
 *    Author   : Dale Brisinda
 *		 <dale@localhost>
 *
 *    Last modified on "Sat Jan 21 02:14:02 1995"
 *    Copyright (c) 1995, Dale Brisinda. All rights reserved.
 *
 * $Id: CanvasView.m,v 1.4 1995/01/21 09:19:16 dale Exp $
 *
 * $Log: CanvasView.m,v $
 * Revision 1.4  1995/01/21 09:19:16  dale
 * Modified error messages.
 *
 * Revision 1.3  1995/01/21  08:53:14  dale
 * Added some additional documentation.
 *
 * Revision 1.2  1995/01/21  04:01:26  dale
 * Added support for choice of cursors while drawing.
 *
 * Revision 1.1  1995/01/20  11:42:00  dale
 * Initial revision
 *
 */

#import <tabletkit/tabletkit.h>
#import "CanvasView.h"

/* Axis resolution for scaling. We use these values, because this is the
 * resolution we set the tablet at when the tabletDriver class was created.
 * This scaling allows us to continuously have a one-to-one mapping of the
 * tablet area to the view area (bounds).
 */
#define RESX 1120.0
#define RESY 832.0

@implementation CanvasView


/* INITIALIZING AND FREEING **************************************************/


- initFrame:(NXRect *)frameRect
{
    [super initFrame:frameRect];

    // drawing attributes
    lineWidth = 1.0;
    lineColor = NX_COLORBLACK;

    // view bounds attributes
    maxBounds = lastBounds = bounds;

    shouldUpdateImage = NO;
    copyPSCode = NO;

    // reset last event
    lastEvent.location.x = lastEvent.location.y = -1.0;

    // create default cursor image
    cursor = [NXImage findImageNamed:"Pencil.tiff"];
    
    return self;
}

- free
{
    [image free];
    [imageCopy free];
    return [super free];
}

- awakeFromNib
{
    NXSize minSize = {50.0, 79.0};   // corresponds to 48x48 icon size

    // window attributes
    [window setBackgroundColor:NX_COLORWHITE];
    [window setMinSize:&minSize];

    image = [[NXImage alloc] initSize:&(bounds.size)];
    [image setUnique:YES];
    if (![image useCacheWithDepth:NX_TwentyFourBitRGBDepth])
	NXLogError("Unable to use cached image rep. (awakeFromNib).");
    if ([image lockFocus]) {
	PScompositerect(bounds.origin.x, bounds.origin.y, 
			bounds.size.width, bounds.size.height, NX_CLEAR);
	[image unlockFocus];
    } else
	NXLogError("Unable to lock focus for image (awakeFromNib).");

    // create image copy
    imageCopy = [image copy];

    return self;
}


/* WINDOW RESIZE NOTIFICATION ************************************************/


/* Window resizing notification is done so we can save the current bounds
 * rectangle, and update the maximum bounds rectangle encountered. We do this
 * so that the contents of an image are never truncated when the view shrinks 
 * in size. The image size will simply be as large as the largest resizing of 
 * the view.
 */


- windowWillResize
{
    lastBounds = bounds;
    return self;
}

- windowDidResize
{
    NXRect lastMaxBounds = maxBounds;

    // reset last event
    lastEvent.location.x = lastEvent.location.y = -1.0;

    // always take maximum image dimensions for the resizing operation so 
    // actual image contents are intact (not truncated)

    maxBounds.size.width = MAX(MAX(bounds.size.width, 
				   lastBounds.size.width),
			       maxBounds.size.width);
    maxBounds.size.height = MAX(MAX(bounds.size.height, 
				    lastBounds.size.height),
				maxBounds.size.height);

    // indicate changes have been made if window got bigger than lastMaxBounds
    if (maxBounds.size.width > lastMaxBounds.size.width ||
	maxBounds.size.height > lastMaxBounds.size.height)
	[window setDocEdited:YES];

    // Used in drawSelf:: to determine if the image should be updated. In this
    // case it should be since the window (and view) were resized.
    shouldUpdateImage = YES;

    return self;
}


/* TABLET EVENT TRACKING *****************************************************/


/* Track the movement of the cursor or stylus and plot. Returns self. */
- trackEvent:(NXEvent *)theEvent
{
    static NXPoint point1, point2;

    // map tablet coordinate to canvas coordinate (scale)
    point2.x = theEvent->location.x * (bounds.size.width / RESX);
    point2.y = theEvent->location.y * (bounds.size.height / RESY);

    // Pressing both the tip and the barrel button simultaneously on the 
    // Summagraphics 1201 stylus, has the effect of acting like a third button.
    // However, in this example we only draw when the tip button is down. This
    // is particularly useful when the user is drawing very quickly -- like 
    // signing signatures for example.

    // only draw when tip button is down (dragged event w/ primary button down)
    if (theEvent->TK_SUBTYPE == TK_STYLUSDRAGGED && 
	theEvent->TK_BUTTON == TK_BUTTON1) {
						
	if (lastEvent.location.x < 0.0 || lastEvent.location.y < 0.0) {
	    point1.x = point2.x; 
	    point1.y = point2.y;
	} else {
	    point1.x = lastEvent.location.x;
	    point1.y = lastEvent.location.y;
	}
	    
	// draw the line segment
	[self drawLine:&point1 :&point2];

	// indicate changes have been made if not already indicated
	if (![window isDocEdited])
	    [window setDocEdited:YES];
    }

    // display the cursor as instance drawing if it exists
    if (cursor) {
	[self lockFocus];
	PSsetinstance(YES);
	PSnewinstance();
	[cursor composite:NX_SOVER toPoint:&point2];
	PSsetinstance(NO);
	[self unlockFocus];
    }

    lastEvent = *theEvent; 
    lastEvent.location.x = point2.x; 
    lastEvent.location.y = point2.y;
    return self;
}


/* DRAWING *******************************************************************/


- drawSelf:(const NXRect *)rects :(int)rectCount
{
    static NXPoint point = {0.0, 0.0};

    // We only want to composite the image on screen when we absolutely have
    // to, since compositing is relatively slow when we are painting. Note, 
    // when saving EPS we want to composite the contents of the image into the
    // view in a slightly different manner, since the view's postscript gets 
    // written out to a stream or file.

    if (shouldUpdateImage) {

	// resize copy of image
	[imageCopy setSize:&(maxBounds.size)];

	// The basic idea here is to copy the contents of image into imageCopy,
	// then clear the contents of image so new areas (after resizing) are 
	// filled with transparency, and finally copy the original image (in 
	// imageCopy) back into image.

	if ([imageCopy lockFocus]) {

	    // Clear imageCopy making everything transparent so we can then
	    // copy the contents of image using NX_SOVER rather than NX_COPY.
	    // NX_COPY is several times slower than NX_SOVER when transparency
	    // exists in the image.
	    NXSetColor(NX_COLORWHITE);
	    PScompositerect(maxBounds.origin.x, maxBounds.origin.y, 
			    maxBounds.size.width, maxBounds.size.height, 
			    NX_CLEAR);

	    [image composite:NX_SOVER toPoint:&point];
	    [imageCopy unlockFocus];
	} else
	    NXLogError("Unable to lock focus for imageCopy (drawSelf::).");

	// resize image
	[image setSize:&(maxBounds.size)];

	// restore the contents of image (imageCopy -> image) by clearing the
	// contents of image first and then using NX_SOVER
	if ([image lockFocus]) {
	    NXSetColor(NX_COLORWHITE);
	    PScompositerect(maxBounds.origin.x, maxBounds.origin.y, 
			    maxBounds.size.width, maxBounds.size.height, 
			    NX_CLEAR);
	    [imageCopy composite:NX_SOVER toPoint:&point];
	    [image unlockFocus];
	} else
	    NXLogError("Unable to lock focus for image (drawSelf::).");
    }

    // if we have resized the view or are copying PostScript code, composite
    // the current image to the view
    if (shouldUpdateImage || copyPSCode) {
	[image composite:NX_SOVER toPoint:&point];
	shouldUpdateImage = copyPSCode = NO;
    }
    return self;
}

- drawLine:(NXPoint *)point1 :(NXPoint *)point2
{
    // Display what the user is drawing in the view. There seems to be a 
    // problem locking focus the first time this method is invoked for a
    // CanvasView instance. We just ignore the problem, since it doesn't
    // seem to be serious, since the line is drawn just the same.

    [self lockFocus];
    NXSetColor(lineColor);
    PSnewpath();
    PSsetlinewidth(lineWidth);
    PSsetlinejoin(1);   // round line join
    PSsetlinecap(1);    // round cap
    PSmoveto(point1->x, point1->y);
    PSlineto(point2->x, point2->y);
    PSclosepath();
    PSstroke();
    [self unlockFocus];
    [self display];

    // keep a copy of what the user is drawing so we can redraw and save it
    if ([image lockFocus]) {
	NXSetColor(lineColor);
	PSnewpath();
	PSsetlinewidth(lineWidth);
	PSsetlinejoin(1);   // round line join
	PSsetlinecap(1);    // round cap
	PSmoveto(point1->x, point1->y);
	PSlineto(point2->x, point2->y);
	PSclosepath();
	PSstroke();
	[image unlockFocus];
    } else
	NXLogError("Unable to lock focus for image (drawLine::).");

    return self;
}

/* We simply adjust the frame rectangle to the largest frame encountered. This
 * is done so the painted image will not be truncated even if it appears as 
 * such in the view. Before returning, we restore the frame rectangle to its
 * former size. Returns self.
 */
- copyPSCodeInside:(const NXRect *)rect to:(NXStream *)stream
{
    NXRect frameRect = frame;
    NXRect svRect = maxBounds;

    copyPSCode = YES;   // set instance var. to composite the current image in 
                        // the view the next time -drawSelf:: is sent

    [self convertRectToSuperview:&svRect];
    [self setFrame:&svRect];   // set view frame to largest encountered
    [super copyPSCodeInside:rect to:stream];
    [self setFrame:&frameRect];   // restore view frame rectangle

    return self;
}


/* CLEARING THE VIEW *********************************************************/


/* Clear the view and image (with transparency). Returns self. */
- clear
{
    // reset last event
    lastEvent.location.x = lastEvent.location.y = -1.0;

    // Clear the drawing area of the view. There seems to be a problem locking
    // focus on the view here. It seems to never succeed, owever, we just
    // ignore the problem for now, since it doesn't seem to be too serious, 
    // since the view is succesfully cleared just the same.

    [self lockFocus];
    NXSetColor(NX_COLORWHITE);
    NXRectFill(&bounds);
    [self unlockFocus];
    [self display];

    if ([image lockFocus]) {
	PScompositerect(maxBounds.origin.x, maxBounds.origin.y, 
			maxBounds.size.width, maxBounds.size.height, NX_CLEAR);
	[image unlockFocus];
    } else
	NXLogError("Unable to lock focus for image (clear).");

    return self;
}


/* SET METHODS ***************************************************************/


- setLineWidth:(float)width
{
    lineWidth = width;
    return self;
}

- setLineColor:(NXColor)color
{
    lineColor = color;
    return self;
}

/* Associates anImage with the view. We make a local copy of the image, so it
 * is the responsibility of the caller to free the passed copy. Not only do we
 * make the association, but we resize and place the window to fit the image.
 * Returns self.
 */
- setImage:(NXImage *)anImage
{
    NXRect imageRect = {0.0, 0.0, 0.0, 0.0};
    NXRect frameRect, windowFrame, newFrame;

    // image will be updated and composited with the next display
    shouldUpdateImage = YES;

    // free default (empty) images
    [image free];
    [imageCopy free];

    [anImage getSize:&(imageRect.size)];

    image = [[NXImage alloc] initSize:&(imageRect.size)];
    [image setUnique:YES];
    if (![image useCacheWithDepth:NX_TwentyFourBitRGBDepth])
	NXLogError("Unable to use cached image rep. (setImage:).");
    if ([image lockFocus]) {
	PScompositerect(imageRect.origin.x, imageRect.origin.y, 
			imageRect.size.width, imageRect.size.height, NX_CLEAR);
	[anImage composite:NX_SOVER toPoint:&(imageRect.origin)];
	[image unlockFocus];
    } else
	NXLogError("Unable to lock focus for image (setImage:).");

    // create image copy
    imageCopy = [image copy];

    // update all view bound sizes (inluding bounds so window can shrink)
    maxBounds = lastBounds = bounds = imageRect;

    // resize the window to completely contain the image (no larger), and 
    // place the window such that the location of the upper left corner of 
    // the window from its original position is unchanged

    [window getFrame:&(windowFrame)];
    newFrame = windowFrame;

    [Window getFrameRect:&frameRect forContentRect:&imageRect 
	    style:NX_RESIZEBARSTYLE];

    newFrame.size.width += (frameRect.size.width - windowFrame.size.width);
    newFrame.size.height += (frameRect.size.height - windowFrame.size.height);
    newFrame.origin.y -= (frameRect.size.height - windowFrame.size.height);
    [window placeWindowAndDisplay:&newFrame];

    return self;
}

/* Sets the cursor to the image contained in the file imageName. If imageName 
 * is NULL, then no cursor will be displayed during drawing. Returns self.
 */
- setCursor:(const char *)imageName
{
    if (cursor)
	[cursor free];

    // create cursor image
    if (imageName) {
	cursor = [NXImage findImageNamed:imageName];
    } else {   // no cursor
	cursor = nil;
	[self lockFocus];
	PSnewinstance();   // clear any exiting cursor
	[self unlockFocus];
    }
    return self;
}


/* QUERY METHODS *************************************************************/


- (NXImage *)image
{
    return image;
}

@end
