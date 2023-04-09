/*
 *    Filename:	NiftyMatrix.m 
 *    Created :	Tue Jan 14 21:48:34 1992 
 *    Author  :	Vince DeMarco
 *		<vince@whatnxt.cuc.ab.ca>
 *
 * LastEditDate "Sat Jun  6 11:28:30 1992"
 *
 * $Log: not supported by cvs2svn $
# Revision 2.1  1992/06/10  14:26:58  vince
# initFrame method has been removed. and the cache Windows
# are now global static variables this has been done
# inorder to have all instances of the NiftyMatrix class share
# the same two cache windows. This saves a few bytes of memory.
#
# Revision 2.0  1992/04/08  03:43:23  vince
# Initial-Release
#
 *
 */


// NiftyMatrix.m
// By Jayson Adams, NeXT Developer Support Team
// You may freely copy, distribute and reuse the code in this example.
// NeXT disclaims any warranty of any kind, expressed or implied, as to its
// fitness for any particular use.

#import <dpsclient/psops.h>
#import <dpsclient/wraps.h>
#import <appkit/timer.h>
#import <appkit/Window.h>
#import <appkit/Application.h>

#import "NiftyMatrix.h"
#import "NiftyMatrixCell.h"

/* These are global to ensure that the application uses the least amount of memory possible
 * Since the code below resizes the offscreen caches each time it uses them, this is possible.
 */
static id nifty_matrixCache;
static id nifty_cellCache;

@implementation NiftyMatrix


#define startTimer(timer) if (!timer) timer = NXBeginTimer(NULL, 0.1, 0.01);

#define stopTimer(timer) if (timer) { \
    NXEndTimer(timer); \
    timer = NULL; \
}

#define MOVE_MASK NX_MOUSEUPMASK|NX_MOUSEDRAGGEDMASK


/* instance methods */

- free
{
    [nifty_matrixCache free];
    [nifty_cellCache free];

    nifty_matrixCache=nil;
    nifty_cellCache=nil;

    return [super free];
}


- mouseDown:(NXEvent *)theEvent
{
    NXPoint		mouseDownLocation, mouseUpLocation, mouseLocation;
    int			eventMask, row, column, newRow;
    NXRect		visibleRect, cellCacheBounds, cellFrame;
    id			matrixCacheContentView, cellCacheContentView;
    float		dy;
    NXEvent		*event, peek;
    NXTrackingTimer	*timer = NULL;
    BOOL		scrolled = NO;

    /* if the current window is not the key window, and the user simply clicked on the matrix 
     * inorder to activate the window.
     * In this case simply return and do nothing
     */
    if (theEvent->data.mouse.click == -1) { 
	return self;
    }

    /* if the user double clicked on the cell then toggle the cell */
    if (theEvent->data.mouse.click == 2) { 
	mouseDownLocation = theEvent->location;
	[self convertPoint:&mouseDownLocation fromView:nil];
	[self getRow:&row andCol:&column forPoint:&mouseDownLocation];
	[[self cellAt:row :column] toggle];
	[self display];
	[self sendAction];
	return self;
    }

    /* prepare the cell and matrix cache windows */
    [self setupCacheWindows];
    
    /* we're now interested in mouse dragged events */
    eventMask = [window addToEventMask:NX_MOUSEDRAGGEDMASK];

    /* find the cell that got clicked on and select it */
    mouseDownLocation = theEvent->location;
    [self convertPoint:&mouseDownLocation fromView:nil];
    [self getRow:&row andCol:&column forPoint:&mouseDownLocation];
    activeCell = [self cellAt:row :column];
    [self selectCell:activeCell];
    [self getCellFrame:&cellFrame at:row :column];
    
    /* draw a "well" in place of the selected cell (see drawSelf::) */
    [self lockFocus];
    [[self drawSelf:&cellFrame :1] unlockFocus];
    
    /* copy what's currently visible into the matrix cache */
    matrixCacheContentView = [nifty_matrixCache contentView];
    [matrixCacheContentView lockFocus];
    [self getVisibleRect:&visibleRect];
    [self convertRect:&visibleRect toView:nil];
    PScomposite(NX_X(&visibleRect), NX_Y(&visibleRect),
    		NX_WIDTH(&visibleRect), NX_HEIGHT(&visibleRect),
		[window gState], 0.0, NX_HEIGHT(&visibleRect), NX_COPY);
    [matrixCacheContentView unlockFocus];

    /* image the cell into its cache */
    cellCacheContentView = [nifty_cellCache contentView];
    [cellCacheContentView lockFocus];
    [cellCacheContentView getBounds:&cellCacheBounds];
    [activeCell drawSelf:&cellCacheBounds inView:cellCacheContentView];
    [cellCacheContentView unlockFocus];

    /* save the mouse's location relative to the cell's origin */
    dy = mouseDownLocation.y - cellFrame.origin.y;
    
    /* from now on we'll be drawing into ourself */
    [self lockFocus];
    
    event = theEvent;
    while (event->type != NX_MOUSEUP) {
      
	/* erase the active cell using the image in the matrix cache */
	[self getVisibleRect:&visibleRect];
	PScomposite(NX_X(&cellFrame), NX_HEIGHT(&visibleRect) -
		    NX_Y(&cellFrame) + NX_Y(&visibleRect) -
		    NX_HEIGHT(&cellFrame), NX_WIDTH(&cellFrame),
		    NX_HEIGHT(&cellFrame), [nifty_matrixCache gState],
		    NX_X(&cellFrame), NX_Y(&cellFrame) + NX_HEIGHT(&cellFrame),
		    NX_COPY);
	
	/* move the active cell */
	mouseLocation = event->location;
	[self convertPoint:&mouseLocation fromView:nil];
	cellFrame.origin.y = mouseLocation.y - dy;
	
	/* constrain the cell's location to our bounds */
	if (NX_Y(&cellFrame) < NX_X(&bounds) ) {
	    cellFrame.origin.y = NX_X(&bounds);
	} else if (NX_MAXY(&cellFrame) > NX_MAXY(&bounds)) {
	    cellFrame.origin.y = NX_HEIGHT(&bounds) - NX_HEIGHT(&cellFrame);
	}

	/*
	 * make sure the cell will be entirely visible in its new location (if
	 * we're in a scrollView, it may not be)
	 */
	if (!NXContainsRect(&visibleRect, &cellFrame) && mFlags.autoscroll) {	
	    /*
	     * the cell won't be entirely visible, so scroll, dood, scroll, but
	     * don't display on-screen yet
	     */
	    [window disableFlushWindow];
	    [self scrollRectToVisible:&cellFrame];
	    [window reenableFlushWindow];
	    
	  /* copy the new image to the matrix cache */
	    [matrixCacheContentView lockFocus];
	    [self getVisibleRect:&visibleRect];
	    [self convertRectFromSuperview:&visibleRect];
	    [self convertRect:&visibleRect toView:nil];
	    PScomposite(NX_X(&visibleRect), NX_Y(&visibleRect),
			NX_WIDTH(&visibleRect), NX_HEIGHT(&visibleRect),
			[window gState], 0.0, NX_HEIGHT(&visibleRect),
			NX_COPY);
	    [matrixCacheContentView unlockFocus];
	    
	    /*
	     * note that we scrolled and start generating timer events for
	     * autoscrolling
	     */
	    scrolled = YES;
	    startTimer(timer);
	} else {
	  /* no scrolling, so stop any timer */
	    stopTimer(timer);
	}
      
	/* composite the active cell's image on top of ourself */
	PScomposite(0.0, 0.0, NX_WIDTH(&cellFrame), NX_HEIGHT(&cellFrame),
		    [nifty_cellCache gState], NX_X(&cellFrame),
		    NX_Y(&cellFrame) + NX_HEIGHT(&cellFrame), NX_COPY);
	
	/* now show what we've done */
	[window flushWindow];
	
	/*
	 * if we autoscrolled, flush any lingering window server events to make
	 * the scrolling smooth
	 */
	if (scrolled) {
	    NXPing();
	    scrolled = NO;
	}
	
	/* save the current mouse location, just in case we need it again */
	mouseLocation = event->location;
	
	if (![NXApp peekNextEvent:MOVE_MASK into:&peek]) {
	    /*
	     * no mouseMoved or mouseUp event immediately avaiable, so take
	     * mouseMoved, mouseUp, or timer
	     */
	    event = [NXApp getNextEvent:MOVE_MASK|NX_TIMERMASK];
	} else {
	    /* get the mouseMoved or mouseUp event in the queue */
	    event = [NXApp getNextEvent:MOVE_MASK];
	}
	
	/* if a timer event, mouse location isn't valid, so we'll set it */
	if (event->type == NX_TIMER) {
	    event->location = mouseLocation;
	}
    }
    
    /* mouseUp, so stop any timer and unlock focus */
    stopTimer(timer);
    [self unlockFocus];
    
    /* find the cell under the mouse's location */
    mouseUpLocation = event->location;
    [self convertPoint:&mouseUpLocation fromView:nil];
    if (![self getRow:&newRow andCol:&column forPoint:&mouseUpLocation]) {
	/* mouse is out of bounds, so find the cell the active cell covers */
	[self getRow:&newRow andCol:&column forPoint:&(cellFrame.origin)];
    }
    
    /* we need to shuffle cells if the active cell's going to a new location */
    if (newRow != row) {
	/* no autodisplay while we move cells around */
	[self setAutodisplay:NO];
	if (newRow > row) {
	    /* adjust selected row if before new active cell location */
	    if (selectedRow <= newRow) {
		selectedRow--;
	    }
	
	    /*
	     * push all cells above the active cell's new location up one row so
	     * that we fill the vacant spot
	     */
	    while (row++ < newRow) {
		cell = [self cellAt:row :0];
		[self putCell:cell at:(row - 1) :0];
	    }
	    /* now place the active cell in its new home */
	    [self putCell:activeCell at:newRow :0];
	} else if (newRow < row) {
	    /* adjust selected row if after new active cell location */
	    if (selectedRow >= newRow) {
		selectedRow++;
	    }
	
	    /*
	     * push all cells below the active cell's new location down one row
	     * so that we fill the vacant spot
	     */
	    while (row-- > newRow) {
		cell = [self cellAt:row :0];
		[self putCell:cell at:(row + 1) :0];
	    }
	    /* now place the active cell in its new home */
	    [self putCell:activeCell at:newRow :0];
	}
      
	/* if the active cell is selected, note its new row */
	if ([activeCell state]) {
	    selectedRow = newRow;
	}
	
	/* make sure the active cell's visible if we're autoscrolling */
	if (mFlags.autoscroll) {
	    [self scrollCellToVisible:newRow :0];
	}
      
	/* no longer dragging the cell */
	activeCell = 0;
    
	/* size to cells after all this shuffling and turn autodisplay back on */
	[[self sizeToCells] setAutodisplay:YES];
    } else {
	/* no longer dragging the cell */
	activeCell = 0;
    }
    
    /* now redraw ourself */
    [self clearSelectedCell];
    [self drawCellInside:activeCell];
    [self display];
    
    /* set the event mask to normal */
    [window setEventMask:eventMask];

    /* do whatever's required for a mouse click */
    [self sendAction];
    
    return self;
}

- drawSelf:(NXRect *)rects :(int)count
{
    int		row, col;
    NXRect	cellBorder;
    int		sides[] = {NX_XMIN, NX_YMIN, NX_XMAX, NX_YMAX, NX_XMIN,
    			   NX_YMIN};
    float	grays[] = {NX_DKGRAY, NX_DKGRAY, NX_WHITE, NX_WHITE, NX_BLACK,
			   NX_BLACK};
			   
    /* do the regular drawing */
    [super drawSelf:rects :count];
    
    /* draw a "well" if the user's dragging a cell */
    if (activeCell) {
	/* get the cell's frame */
	[self getRow:&row andCol:&col ofCell:activeCell];
	[self getCellFrame:&cellBorder at:row :col];
      
	/* draw the well */
	if (NXIntersectsRect(&cellBorder, &(rects[0]))) {
	    NXDrawTiledRects(&cellBorder, (NXRect *)0, sides, grays, 6);
	    PSsetgray(0.17);
	    NXRectFill(&cellBorder);
	}
    }
    
    return self;
}

- setupCacheWindows
{
    NXRect	visibleRect;

    /* create the matrix cache window */
    [self getVisibleRect:&visibleRect];
    nifty_matrixCache = [self sizeCacheWindow:nifty_matrixCache to:&(visibleRect.size)];
    
    /* create the cell cache window */
    nifty_cellCache = [self sizeCacheWindow:nifty_cellCache to:&cellSize];

    return self;
}

- sizeCacheWindow:cacheWindow to:(NXSize *)windowSize
{
    NXRect	cacheFrame;
    
    if (!cacheWindow) {
      /* create the cache window if it doesn't exist */
	cacheFrame.origin.x = cacheFrame.origin.y = 0.0;
	cacheFrame.size = *windowSize;
	cacheWindow = [[[Window allocFromZone: [self zone]] initContent:&cacheFrame
				       style:NX_PLAINSTYLE
				       backing:NX_RETAINED
				       buttonMask:0
				       defer:NO] reenableDisplay];
      /* flip the contentView since we are flipped */
	[[cacheWindow contentView] setFlipped:YES];
    } else {
      /* make sure the cache window's the right size */
	[cacheWindow getFrame:&cacheFrame];
	if (cacheFrame.size.width != windowSize->width ||
      	    cacheFrame.size.height != windowSize->height) {
	    [cacheWindow sizeWindow:windowSize->width
			    	   :windowSize->height];
	}
    }
    
    return cacheWindow;
}

@end
