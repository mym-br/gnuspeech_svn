/*  HEADER FILES  ************************************************************/
#import "DragView.h"
#import "Scratchpad.h"
#import <appkit/appkit.h>


@implementation DragView

- initFrame:(const NXRect *)theFrame
{
    const char *fileType[] = {NXTIFFPboardType, NXFilenamePboardType};

    /*  DO REGULAR INITIALIZATION  */
    [super initFrame:theFrame];
    
    /*  REGISTER THE PASTEBOARD WHICH THE VIEW ACCEPTS  */
    [self registerForDraggedTypes:fileType count:2];

    /*  INITIALIZE FILENAME BUFFERS  */
    temporaryFilename[0] = permanentFilename[0] = '\0';
    
    return self;
}



- (NXDragOperation)draggingEntered:sender
{
    /*  DISPLAY THE TEMPORARY IMAGE  */
    temporaryImage = [sender draggedImage];
    [self display];

    /*  DISPLAY THE FILENAME IN DARK GRAY  */
    if (filenameDisplay) {
	[filenameDisplay setTextGray:NX_DKGRAY];
	[self copyFilenameOnPasteboard:[sender draggingPasteboard]
	      to:temporaryFilename];
	[filenameDisplay setStringValue:temporaryFilename];
    }

    return NX_DragOperationGeneric;
}



- (NXDragOperation)draggingUpdated:sender
{
    return NX_DragOperationGeneric;
}



- draggingExited:sender
{
    /*  DON'T DISPLAY TEMPORARY IMAGE ANYMORE  */
    temporaryImage = nil;
    [self display];

    /*  IF THERE IS A PERMANENT FILENAME, DISPLAY IT IN BLACK (OR DISPLAY BLANK)  */
    [filenameDisplay setTextGray:NX_BLACK];
    [filenameDisplay setStringValue:permanentFilename];

    return self;
}



- (BOOL)prepareForDragOperation:sender
{
    NXPoint point;
    NXSize size;
    
    /*  FIND ORIGIN THAT CENTERS IMAGE WITHIN VIEW  */
    [temporaryImage getSize:&size];
    point.x = (NX_WIDTH(&bounds) - size.width) / 2.0;
    point.y = (NX_HEIGHT(&bounds) - size.height) / 2.0;
    
    /*  CONVERT THE ORIGIN TO A SCREEN COORDINATE  */
    [self convertPoint:&point toView:nil];
    [[self window] convertBaseToScreen:&point];

    /*  SLIDE IMAGE TO ITS FINAL RESTING PLACE  */
    [sender slideDraggedImageTo:&point];

    return YES;
}



- (BOOL)performDragOperation:sender
{
    /*  WE NO LONGER USE THE TEMPORARY IMAGE (IT SHOULD NEVER BE FREED)  */
    temporaryImage = nil;

    /*  FREE OLD PERMANENT IMAGE, IF IT EXISTS  */
    if (permanentImage)
	[permanentImage free];

    /*  GET A COPY OF THE NEW PERMANENT IMAGE  */
    permanentImage = [sender draggedImageCopy];

    /*  DISPLAY THE IMAGE (WITH NO GHOSTING)  */
    [self display];
    
    /*  DISPLAY THE FILENAME IN BLACK  */
    if (filenameDisplay) {
	[filenameDisplay setTextGray:NX_BLACK];
	/*  SET THE PERMANENT FILENAME  */
	strcpy(permanentFilename,temporaryFilename);
    }
    
    return YES;
}



- concludeDragOperation:sender
{
    /*  DELEGATE SHOULD SPEAK FILE ON THE DRAGGING PASTEBOARD  */
    if (speachDelegate)
	[speachDelegate speakFileOnPasteboard:[sender draggingPasteboard]];

    return self;
}



- (BOOL)shouldDelayWindowOrderingForEvent:(NXEvent *)theEvent
{
    return YES;
}



- drawSelf:(const NXRect *)rects :(int)num
{
    NXSize size;
    NXPoint point;

    if (temporaryImage) {
	/*  FIND ORIGIN THAT CENTERS IMAGE WITHIN VIEW  */
	[temporaryImage getSize:&size];
	point.x = (NX_WIDTH(&bounds) - size.width) / 2.0;
	point.y = (NX_HEIGHT(&bounds) - size.height) / 2.0;

	/*  DISPLAY GHOST IMAGE  */
	PSsetgray(NX_DKGRAY);
	NXRectFill(rects);
	[temporaryImage composite:NX_SOVER toPoint:&point];
	PScompositerect(NX_X(rects), NX_Y(rects),
			NX_WIDTH(rects), NX_HEIGHT(rects), NX_PLUSL);
    }
    else if (permanentImage) {
	/*  FIND ORIGIN THAT CENTERS IMAGE WITHIN VIEW  */
	[permanentImage getSize:&size];
	point.x = (NX_WIDTH(&bounds) - size.width) / 2.0;
	point.y = (NX_HEIGHT(&bounds) - size.height) / 2.0;

	/*  CLEAR VIEW FIRST  */
	PSsetgray(NX_LTGRAY);
	NXRectFill(rects);

	/*  DISPLAY PERMANENT IMAGE  */
	[permanentImage composite:NX_SOVER toPoint:&point];
    }
    else {
	/*  CLEAR VIEW  */
	PSsetgray(NX_LTGRAY);
	NXRectFill(rects);
    }


    return self;
}



- free
{
    /*  FREE PERMANENT IMAGE, IF NECESSARY  */
    if (permanentImage)
	[permanentImage free];

    /*  DO REGULAR FREE  */
    return [super free];
}



- copyFilenameOnPasteboard:pasteboard to:(char *)filenameBuffer
{
    char *path;
    int pathLength;

    /*  GET THE PATH FROM THE DRAGGING PASTEBOARD  */
    if ([pasteboard readType:NXFilenamePboardType data:&path length:&pathLength]) {
	/*  MAKE SURE PATH NAME IS NULL TERMINATED  */
	path[pathLength] = '\0';

	/*  COPY FILENAME IN PATH TO BUFFER  */
	if (path && (strlen(path) > 1))
	    strcpy(filenameBuffer, (rindex(path,'/') + 1));
	else if (path && (strlen(path) == 1))
	    strcpy(filenameBuffer, path);
	else
	    filenameBuffer[0] = '\0';
    }

    /*  DEALLOCATE OLD PATH BUFFER MEMORY, IF NECESSARY  */
    if (path)
	vm_deallocate(task_self(),(vm_address_t)path,(vm_size_t)pathLength);

    return self;
}

@end
