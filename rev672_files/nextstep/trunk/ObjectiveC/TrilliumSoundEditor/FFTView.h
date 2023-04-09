
#import <appkit/appkit.h>
#import "FFTTitleView.h"
#import "FFT.h"

/*===========================================================================

	Object: FFTView
	Purpose: Main viewing area of the FFT output

	Author: Craig-Richard Taube-Schock
	Based on Object by: Steven Nygard.
	Date: Nov. 1, 1993

History:
	Nov. 23, 1993.  Documentation Completed.

===========================================================================*/


@interface FFTView:View
{
	FFTTitleView	*titleView;
	NXImage		*image;
	unsigned char 	*bm;
	int 		bml;
	FFT 		*fft;
	int 		bmWidth, bmHeight;
	id 		lr;
	Font 		*timeFont;
	Font 		*titleFont;

	int 		pixelWidth;

	/* Grid things */
	BOOL 		displayGrid;
	float 		freqInterval;
	float 		timeInterval;
	/*id 		freqInterField;
	id 		timeInterField;*/

	/* Scaling things */
	BOOL 		linear; /* actually better as an enum, but... */
	float 		minScale;
	float 		maxScale;
	float 		theMin;
	float 		theMax;

	BOOL 		negative;
	NXColorSpace 	theColorSpace;
}

- initFrame:(const NXRect *)frameRect;
- drawSelf:(const NXRect *)rects :(int)rectCount;
- free;

- theDrawing:sender;
- updateBitmap:sender;
- recache:sender;
- setFFT:anFFT;
- fft;

- setTitleView: aView;
- titleView;

- (int)pixelWidth;
- setPixelWidth:(int)aWidth;

- (BOOL)displayGrid;
- setDisplayGrid:(BOOL)b;
- (float)freqInterval;
- setFreqInterval:(float)x;
- (float)timeInterval;
- setTimeInterval:(float)x;
- (BOOL)scaleLinear;
- setScaleLinear:(BOOL)b;
- (float)minScale;
- setMinScale:(float)x;
- (float)maxScale;
- setMaxScale:(float)x;
- (float)theMin;
- (float)theMax;

- (BOOL)negative;
- setNegative:(BOOL)b;

@end
