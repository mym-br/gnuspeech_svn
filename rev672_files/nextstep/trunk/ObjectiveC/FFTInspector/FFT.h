
#import <objc/Object.h>
#import "structs.h"

@interface FFT:Object
{
  struct _FFTheader FFTHeader;
  struct _FFTheader _scratchFFTHeader;
  float *data;
  /*int dataSize;*/
}

- initFromFFTfile:(const char *)filename;
- initFromFFTfile:(const char *)filename headerOnly:(BOOL)header;
- free;

- (BOOL)hanningWindow;
- (int)windowSlide;
- (int)numberOfWindows;
- (int)binSize;
- (int)samplingRate;
- (char *)comment;
- (float *)data;
- (int)dataSize;

@end
