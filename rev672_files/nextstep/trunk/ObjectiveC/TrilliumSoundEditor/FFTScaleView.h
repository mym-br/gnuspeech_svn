
#import <appkit/appkit.h>
#import "FFT.h"

/*===========================================================================

	Object: FFTScaleView
	Original Author: Steven Nygard
	Modified by: Craig-Richard Taube-Schock

	Purpose: One of the three sub-views of the FFT display.  Displays
		the frequency scale on the left hand size of the display.

	Date: Nov. 1, 1993

History:
	Nov. 23, 1993.  Documentation Completed

===========================================================================*/

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

