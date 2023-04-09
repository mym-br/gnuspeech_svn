#import <AppKit/AppKit.h>

@interface PositionView:NSView
{
    id background;
    id arrow;

    NSSize arrowSize;
    NSPoint arrowPosition;
    float offset;
}

- initWithFrame:(NSRect)frameRect;
- (void)dealloc;

- (void)drawPosition:(float)position;

@end
