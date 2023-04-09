/*
 *    Filename : CanvasControl.h 
 *    Created  : Tue Jan 17 13:28:53 1995 
 *    Author   : Dale Brisinda
 *		 <dale@localhost>
 *
 *    Last modified on "Fri Jan 20 20:39:17 1995"
 *    Copyright (c) 1995, Dale Brisinda. All rights reserved.
 *
 * $Id: CanvasControl.h,v 1.2 1995/01/21 04:01:26 dale Exp $
 *
 * $Log: CanvasControl.h,v $
 * Revision 1.2  1995/01/21 04:01:26  dale
 * Added support for choice of cursors while drawing.
 *
 * Revision 1.1  1995/01/20  11:41:53  dale
 * Initial revision
 *
 */

#import <appkit/appkit.h>

@interface CanvasControl:Object
{
    id window;           // the window containing the custom view object
    id canvasView;       // the custom view object
    id savePanel;        // shared instance of the save panel

    BOOL firstResize;    // first windowWillResize:toSize: message in 
                         // windowWillResize:toSize: message stream?
    char *filename;
}

/* INITIALIZING AND FREEING */
- init;
- free;

/* WINDOW DELEGATION */
- windowWillClose:sender;
- windowWillResize:sender toSize:(NXSize *)frameSize;
- windowDidResize:sender;
- windowDidBecomeKey:sender;

/* TABLET EVENT TRACKING */
- trackEvent:(NXEvent *)theEvent;

/* SET METHODS */
- setLineWidth:(float)width;
- setLineColor:(NXColor)color;
- setFilename:(const char *)fname;
- setCursor:(const char *)imageName;

/* QUERY METHODS */
- window;
- (const char *)filename;

/* CLEARING THE CANVAS */
- clearCanvas;

/* DOCUMENT OPERATIONS */
- openImageFile:(const char *)fullPath;
- saveTIFF:(const char *)fname;
- saveEPS:(const char *)fname;

/* FIRST RESPONDER METHODS */
- saveAs:sender;
- save:sender;
- close:sender;

@end
