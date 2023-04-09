
#import <appkit/appkit.h>
#import "FFT.h"

@interface FFTView:View
{
	NXImage		*image;
	unsigned char 	*bm;
	int 		bml;
	FFT 		*fft;
	int 		bmWidth, bmHeight;
	id 		lr;
	Font 		*timeFont;

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
