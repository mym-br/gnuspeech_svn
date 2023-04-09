#import <appkit/appkit.h>

@interface DragView:View
{
    id speachDelegate;
    id filenameDisplay;

    char temporaryFilename[MAXPATHLEN];
    char permanentFilename[MAXPATHLEN];

    NXImage *temporaryImage;
    NXImage *permanentImage;
}

- initFrame:(const NXRect *)theFrame;

- (NXDragOperation)draggingEntered:sender;
- (NXDragOperation)draggingUpdated:sender;
- draggingExited:sender;
- (BOOL)prepareForDragOperation:sender;
- (BOOL)performDragOperation:sender;
- concludeDragOperation:sender;

- (BOOL)shouldDelayWindowOrderingForEvent:(NXEvent *)theEvent;
- drawSelf:(const NXRect *)rects :(int)num;
- free;

- copyFilenameOnPasteboard:pasteboard to:(char *)filenameBuffer;
@end
