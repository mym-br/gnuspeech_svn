#import <AppKit/AppKit.h>

@interface ParameterView:NSView
{
    NSRect activeArea;
    id  background;
    id  foreground;
}

- initWithFrame:(NSRect)frameRect;
- (void)dealloc;

- (void)drawBackground;
- (void)drawRiseTime:(float)riseTime fallTimeMin:(float)fallTimeMin fallTimeMax:(float)fallTimeMax;

@end
