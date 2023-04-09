
#import <appkit/appkit.h>
#import "FFTScaleView.h"

@interface FFTScrollView:ScrollView
{
  FFTScaleView *scaleView;
}

- initFrame:(const NXRect *)frameRect;
- drawSelf:(const NXRect *)rects :(int)rectCount;
- tile;
- printPSCode:sender;

- scaleView;

@end
