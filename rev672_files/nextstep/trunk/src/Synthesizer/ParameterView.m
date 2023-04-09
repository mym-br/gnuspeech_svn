#import "ParameterView.h"
#import "PSwraps.h"


#define SIDE_MARGIN     10.0
#define TOP_MARGIN      10.0


@implementation ParameterView

- initWithFrame:(NSRect)frameRect
{
    /*  DO REGULAR INITIALIZATION  */
    [super initWithFrame:frameRect];

    /*  CALCULATE ACTIVE AREA  */
    activeArea = NSMakeRect(NSMinX([self bounds]), NSMinY([self bounds]), NSWidth([self bounds]), NSHeight([self bounds]));
    activeArea = NSInsetRect(activeArea , SIDE_MARGIN , TOP_MARGIN);

    /*  ALLOCATE A BACKGROUND NXIMAGE  */
    background = [[NSImage alloc] initWithSize:(frameRect.size)];

    /*  DRAW BACKGROUND  */
    [self drawBackground];

    /*  ALLOCATE A FORGROUND NXIMAGE  */
    foreground = [[NSImage alloc] initWithSize:(frameRect.size)];
    
    return self;
}



- (void)dealloc
{
    /*  FREE BACKGROUND NXIMAGE  */
    [background release];
    
    /*  FREE FOREGROUND NXIMAGE  */
    [foreground release];
    
    /*  DO REGULAR FREE  */
    { [super dealloc]; return; };
}



- (void)drawBackground
{
    /*  LOCK FOCUS ON BACKGROUND NXIMAGE  */
    [background lockFocus];

    /*  DRAW WHITE BACKGROUND WITH BORDER  */
    NSDrawWhiteBezel([self bounds] , [self bounds]);

    /*  DRAW LIGHT GRAY ENCLOSURE  */
    PSrectangle(NSMinX(activeArea), NSMinY(activeArea),
		NSWidth(activeArea), NSHeight(activeArea),
		1.0, NSLightGray);

    /*  UNLOCK FOCUS ON BACKGROUND NXIMAGE  */
    [background unlockFocus]; 
}



- (void)drawRiseTime:(float)riseTime fallTimeMin:(float)fallTimeMin fallTimeMax:(float)fallTimeMax
{
    /*  LOCK FOCUS ON THE FOREGROUND NXIMAGE  */
    [foreground lockFocus];

    /*  CLEAR THE NXIMAGE  */
    [foreground compositeToPoint:[self bounds].origin operation:NSCompositeClear];

    /*  DRAW THE PULSE PARAMETERS  */
    PSpulseparameter(NSMinX(activeArea), NSMinY(activeArea),
		     NSWidth(activeArea), NSHeight(activeArea),
		     riseTime, fallTimeMin, fallTimeMax);

    /*  UNLOCK FOCUS ON THE FOREGROUND NXIMAGE  */
    [foreground unlockFocus];

    /*  DISPLAY THE COMBINED IMAGES  */
    [self display]; 
}



- (void)drawRect:(NSRect)rects
{
    /*  COMPOSITE THE FOREGROUND IMAGE OVER THE BACKGROUND  */
    [background compositeToPoint:(rects.origin) operation:NSCompositeSourceOver];
    [foreground compositeToPoint:(rects.origin) operation:NSCompositeSourceOver];
}

@end
