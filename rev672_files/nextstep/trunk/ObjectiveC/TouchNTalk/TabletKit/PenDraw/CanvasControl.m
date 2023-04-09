/*
 *    Filename : CanvasControl.m 
 *    Created  : Tue Jan 17 13:58:21 1995 
 *    Author   : Dale Brisinda
 *		 <dale@localhost>
 *
 *    Last modified on "Thu Mar 14 16:02:13 1996"
 *    Copyright (c) 1995, Dale Brisinda. All rights reserved.
 *
 * $Id: CanvasControl.m,v 1.3 1996/09/14 03:56:08 dale Exp $
 *
 * $Log: CanvasControl.m,v $
 * Revision 1.3  1996/09/14 03:56:08  dale
 * Removed commented code segments.
 *
 * Revision 1.2  1995/01/21  04:01:26  dale
 * Added support for choice of cursors while drawing.
 *
 * Revision 1.1  1995/01/20  11:41:53  dale
 * Initial revision
 *
 */

#import <tabletkit/tabletkit.h>
#import "PenDraw.h"
#import "CanvasControl.h"
#import "CanvasView.h"

@implementation CanvasControl


/* INITIALIZING AND FREEING **************************************************/


- init
{
    [super init];

    // get shared instance of save panel
    savePanel = [SavePanel new];

    firstResize = YES;   // anticipate next resize -- reset instance var.
    return self;
}

- free
{
    return [super free];
}


/* WINDOW DELEGATE METHODS ***************************************************/


- windowWillClose:sender
{
    if ([sender isDocEdited]) {

	const char *fname;
	int value;
	
	fname = (filename ? filename : [sender title]);
	if (rindex(fname, '/'))
	    fname = rindex(fname, '/') + 1;

	value = NXRunAlertPanel("Save", "Save changes to %s?", 
				"Save", 
				"Don't Save", 
				"Cancel", fname);

	if (value == NX_ALERTDEFAULT)   // save
	    if (![self save:nil])
		return nil;   // didn't save

	if (value == NX_ALERTOTHER)   // cancel
	    return nil;
    }

    [sender setDelegate:nil];   // clear window handle to CanvasControl
    [[NXApp delegate] setCanvasControl:nil];   // clear handle to CanvasControl
    [self free];   // free CanvasControl object
    return self;   // window will free itself on close
}

/* When the user is resizing the window, the delegate (CanvasControl) is sent 
 * a series of windowWillResize:toSize: messages as the window's outline is 
 * dragged. We really only want to pass on the first one to the CanvasView, so
 * we check the firstResize instance var. to see if this is infact the first
 * window resize message in a stream of window resize messages. Returns self.
 */
- windowWillResize:sender toSize:(NXSize *)frameSize
{
    if (firstResize) {
	[canvasView windowWillResize];
	firstResize = NO;
    }
    return self;
}

- windowDidResize:sender
{
    [canvasView windowDidResize];
    firstResize = YES;   // anticipate next resize -- reset instance var.
    return self;
}

- windowDidBecomeKey:sender
{
    id delegate = [NXApp delegate];

    [delegate setCanvasControl:self];
    [canvasView setLineWidth:[delegate lineWidth]];
    [canvasView setLineColor:[delegate lineColor]];
    return self;
}


/* TABLET EVENT TRACKING *****************************************************/


/* Track the movement of the cursor or stylus and plot. Returns self. */
- trackEvent:(NXEvent *)theEvent
{
    [canvasView trackEvent:theEvent];
    return self;
}


/* SET METHODS ***************************************************************/


- setLineWidth:(float)width
{
    [canvasView setLineWidth:width];
    return self;
}

- setLineColor:(NXColor)color
{
    [canvasView setLineColor:color];
    return self;
}

/* Sets the filename instance variable and window title to fname. */
- setFilename:(const char *)fname
{
    if (filename) 
	free(filename);
    filename = malloc(strlen(fname) + 1);
    strcpy(filename, fname);
    [window setTitleAsFilename:fname];
    return self;
}

/* Sets the cursor to the image contained in the file imageName. If imageName 
 * is NULL, then no cursor will be displayed during drawing. Returns self.
 */
- setCursor:(const char *)imageName
{
    [canvasView setCursor:imageName];
    return self;
}


/* QUERY METHODS *************************************************************/


- window
{
    return window;
}

- (const char *)filename
{
    return filename;
}


/* CLEARING THE CANVAS *******************************************************/


- clearCanvas
{
    [canvasView clear];
    return self;
}


/* DOCUMENT OPERATIONS *******************************************************/


- openImageFile:(const char *)fullPath
{
    id image;

    NXStream *stream = NXMapFile(fullPath, NX_READONLY);

    if (!stream)
	return nil;

    // create the EPS or TIFF image from the stream
    image = [[NXImage alloc] initFromStream:stream];
    [image setDataRetained:YES];
    NXCloseMemory(stream, NX_FREEBUFFER);

    // do we have at least one rep.?
    if ([image lastRepresentation] == nil)
	return nil;

    // associate the image with the view
    [canvasView setImage:image];

    // free the image (canvasView has local copy)
    [image free];

    // set the filename and window title
    [self setFilename:fullPath];

    return self;
}

- saveTIFF:(const char *)fname
{
    id image;
    NXStream *stream;

    image = [canvasView image];
    if (stream = NXOpenMemory(NULL, 0, NX_READWRITE))
	[image writeTIFF:stream 
	       allRepresentations:NO
	       usingCompression:NX_TIFF_COMPRESSION_LZW
	       andFactor:0.0];
    NXFlush(stream);
    if (NXSaveToFile(stream, fname))
	perror(filename);
    NXCloseMemory(stream, NX_FREEBUFFER);
    return self;
}

- saveEPS:(const char *)fname
{
    id canvasImage = [canvasView image];
    NXStream *stream;
    NXRect imageRect;

    // get image rectangle
    imageRect.origin.x = imageRect.origin.y = 0.0;
    [canvasImage getSize:&(imageRect.size)];

    // copy postscript code inside imageRect to stream
    if (stream = NXOpenMemory(NULL, 0, NX_READWRITE))
	[canvasView copyPSCodeInside:&imageRect to:stream];

    NXFlush(stream);
    if (NXSaveToFile(stream, fname))
	perror(filename);
    NXCloseMemory(stream, NX_FREEBUFFER);
    return self;
}


/* FIRST RESPONDER METHODS ***************************************************/


- saveAs:sender
{
    const char *directory;
    char *file;

    if (!filename) {   // no filename has been set; set up defaults
	directory = NXHomeDirectory();
	file = (char *)[window title];
    } else {
	file = rindex(filename, '/');
	if (file) {
	    directory = filename;
	    *file = 0;
	    file++;
	} else {
	    directory = filename;
	    file = (char *)[window title];
	}
    }

    // add the accessory view to the save panel
    if (![savePanel accessoryView])
	[savePanel setAccessoryView:[[NXApp delegate] accessoryContentView]];

    // bring up the save panel
    if ([savePanel runModalForDirectory:directory file:file] == NX_OKTAG) {
	[self setFilename:[savePanel filename]];
	return [self save:sender];
    }
    return nil;   // did not save
}

- save:sender
{
    if (!filename)
	return [self saveAs:sender];

    // update window title to indicate file is saving
    [window setTitle:"Saving..."];

    if (!strcmp([savePanel requiredFileType], "tiff")) {   // save TIFF image
	[self saveTIFF:filename];
    } else if (!strcmp([savePanel requiredFileType], "eps")) {   // save EPS
	[self saveEPS:filename];
    }

    // restore window filename
    [window setTitleAsFilename:filename];

    // replace broken X with solid X now that document has been saved
    [window setDocEdited:NO];

    return self;
}

- close:sender
{
    return [window performClose:nil];
}

@end
