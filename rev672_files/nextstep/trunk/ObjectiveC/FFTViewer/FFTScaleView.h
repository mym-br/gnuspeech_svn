
#import <appkit/appkit.h>
#import "FFT.h"

@interface FFTScaleView:View
{
  Font *freqFont;
  Font *freqLabelFont;
  FFT *fft;
  float freqInterval;
}

- initFrame:(const NXRect *)frameRect;
- drawSelf:(const NXRect *)rects :(int)rectCount;

- setFFT:anFFT;
- setFreqInterval:(float)x;

@end

