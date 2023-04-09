
#import <appkit/appkit.h>
#import "FFT.h"

/*===========================================================================

	Object: FFTTitleView
	Purpose: Subview which displays title information within the 
		FFT display

	Author: Craig-Richard Taube-Schock
	Date: Nov. 1, 1993

History:
	Nov. 23, 1993.  Documentation Completed.

===========================================================================*/


@interface FFTTitleView:View
{
	Font	*titleFont;
	FFT	*fft;
}

- initFrame:(const NXRect *)frameRect;
- drawSelf:(const NXRect *)rects :(int)rectCount;

- setFFT:anFFT;

@end

