
#import <math.h>
#import "FFTScrollView.h"
#import "FFTView.h"

/*===========================================================================

	File: FFTView.m
	Author: Craig-Richard Taube-Schock
	Original Object by: Steven Nygard.

===========================================================================*/

@implementation FFTView

/*===========================================================================

	Method:
	Purpose:

===========================================================================*/
- initFrame:(const NXRect *)frameRect
{
	[super initFrame:frameRect];

	/* Allocate Bitmap NXImage object.  Will hold the fft image */
	image = [[NXImage alloc] initSize:&frameRect->size];
	if (![image useDrawMethod:@selector(theDrawing:) inObject :self])
		printf("[image useDrawMethod:inObject:] failed.\n");

	/* Set up Last Representation for Bitmap */
	lr = [image lastRepresentation];
	[lr setNumColors:1];
	[lr setAlpha:NO];
	[lr setBitsPerSample:8];

	[self setFlipped:NO];

	/* Time displayed in Helvetica.  Ohhh, I hate Helvetica! :-) */
	timeFont = [Font newFont:"Helvetica" size:8.0 matrix:NX_IDENTITYMATRIX];
	if (timeFont == nil)
		printf("FFTView - initFrame: font junk failed.\n");

	titleFont = [Font newFont:"Helvetica" size:12.0 matrix:NX_IDENTITYMATRIX];

	/* Bitmap entries are 8-bit.  255 is Black */
	theColorSpace = NX_OneIsBlackColorSpace;
	negative = NO;
	linear = YES;

	/* Each fft window is 2 pixels on display on default. */
	pixelWidth = 2;

	/* Set up defaults */
	displayGrid = YES;
	timeInterval = 0.25;
	freqInterval = 1.0;

	minScale = 0.0;
	maxScale = 1.0;
	theMin = theMax = 0.0;

	return self;
}

/*===========================================================================

	Method:
	Purpose:

===========================================================================*/
- drawSelf:(const NXRect *)rects :(int)rectCount
{
NXPoint myPoint = {0.0, 49.0};
float l, t, x, y;
char buf[20];

	/* clear the view */
	PSsetgray(NX_WHITE);
	PSrectfill(NX_X(rects), NX_Y(rects), NX_WIDTH(rects), NX_HEIGHT(rects));

	/* Composite the bitmap */
	myPoint.x = NX_X(rects);
	if ([image composite:NX_SOVER fromRect:rects toPoint:&myPoint] == nil)
		printf("compositing failed.\n");


	/* Clear space for x-axis stuff */
	PSsetgray(NX_WHITE);
	PSrectfill(0.0, 0.0, NX_WIDTH(&bounds), 49.0);

	/* Draw x-axis. */
	PSsetgray(NX_BLACK);
	PSmoveto(0.0, 49.0);
	PSlineto(NX_WIDTH(&bounds), 49.0);
	PSstroke();

	/* Write time information based on the current fft */
	PSsetgray(NX_BLACK);
	[timeFont set];
	t = 0.0;
	x = 0.0;
	y = displayGrid ? NX_HEIGHT(&bounds) : 49.0;

	/* Draw Time Intervals */
	while (x < [fft numberOfWindows] * pixelWidth)
	{
		x = t / [fft windowSlide] * [fft samplingRate] * pixelWidth ;
		if (x > NX_X(rects) && x < NX_X(rects) + NX_WIDTH(rects))
		{
			PSmoveto(x, 44.0);
			PSlineto(x, y);
			PSstroke();
		}
		PSmoveto(x, 30.0);
		sprintf(buf, "%.2f", t);
		PSshow(buf);
		t += timeInterval;
	}

	/* Display Grid if requested */
	if (fft && displayGrid)
		for (l = 0.0; l <= [fft samplingRate] / 2000.0; l += freqInterval)
		{
			y = 50.0 + 256.0 * l * 2000.0 / [fft samplingRate];
			PSmoveto(NX_X(rects), y);
			PSlineto(NX_X(rects) + NX_WIDTH(rects), y);
			PSstroke();
		}

	[titleView display];

	return self;
}

/*===========================================================================

	Method: free
	Purpose: Free bitmap when object is freed

===========================================================================*/
- free
{
	if (bm)
		free(bm);

	return[super free];
}

/*===========================================================================

	Method: theDrawing
	Purpose: Tell the system how the FFT data is stored and display it.

	NOTE: It would be a good idea to read about NXDrawBitmap in the 
		Documentation if you don't understand what is going on here.
		Basically, data is stored in an arbitrary bitmap.  The 
		display system has to know things like bitmap width, height
		bits per pixel, etc. 

===========================================================================*/
- theDrawing:sender
{
unsigned char *data[] = {bm, 0, 0, 0, 0};
NXRect rect;

	if (bm)
	{
		NXSetRect(&rect, 0.0, 0.0, (float)bmWidth, (float)bmHeight);
		NXDrawBitmap(&rect, bmWidth, bmHeight, 8, 1, 8, bmWidth, NO, NO, theColorSpace, data);
	}

	return self;
}

/*===========================================================================

	Method: updateBitmap
	Purpose: Called when a new fft is set so that the display can 
		be updated.

===========================================================================*/
- updateBitmap:sender
{
float *fp;
int l, m, n, w;
int floatsInWindow = [fft binSize] / 2;
int height = 512 / [fft binSize];
unsigned char *p;
unsigned char  g;
float scaleWidth;
float ftmp;

	scaleWidth = maxScale - minScale;

	/* Clear the bitmap */
	bzero(bm, bml);

	/* Get a pointer to the FFT data.  Remember, don't muck with the FFT data */
	fp = [fft fftData];

	/* Linear Display */
	if (linear)
	{
		/* Display one vertical line for each FFT window */
		for (l = 0; l < [fft numberOfWindows]; l++)
		{
			/* Index into the bitmap. (Basically, an array of unsigned chars */
			p = bm + 255 * bmWidth + pixelWidth * l;

			/* Traverse through FFT data, scale, and display */
			for (m = 0; m < floatsInWindow; m++)
			{
				/* Calculate scaling multiplier */
				ftmp = (*fp - minScale) / scaleWidth;
				if (ftmp > 1.0)
					ftmp = 1.0;
				if (ftmp < 0.0)
					ftmp = 0.0;
				g = ftmp * 255;

				/* Display data N pixels wide */
				for (n = 0; n < height; n++)
				{
					for (w = 0; w < pixelWidth; w++)
						*(p + w) = g;
					p -= bmWidth;
				}
				fp++;
			}
		}
	}
	else
	{
		float maxLn = (float)log10((double)maxScale - (double)minScale + 1.0);

		/* Display one vertical line for each FFT window */
		for (l = 0; l < [fft numberOfWindows]; l++)
		{
			/* Index into the bitmap. (Basically, an array of unsigned chars */
			p = bm + 255 * bmWidth + pixelWidth * l;

			/* Traverse through FFT data, scale, and display */
			for (m = 0; m < floatsInWindow; m++)
			{
				/* Calculate scaling multiplier */
				ftmp = (float)log10((double)(*fp - minScale + 1.0)) / maxLn;
				if (ftmp > 1.0)
					ftmp = 1.0;
				if (ftmp < 0.0)
					ftmp = 0.0;
				g = ftmp * 255;

				/* Display data N pixels wide */
				for (n = 0; n < height; n++)
				{
					for (w = 0; w < pixelWidth; w++)
						*(p + w) = g;
					p -= bmWidth;
				}
				fp++;
			}
		}
	}

	/* Invalidate current representations of this data so that they will be 
	   re-drawn when they are sent a display message */
	[image recache];

	/* Display this view */
	[self display];

	return self;
}

/*===========================================================================

	Method: recache
	Purpose: See method "recache" in NXImage Documentation.

===========================================================================*/
- recache:sender
{
	[image recache];
	[self display];

	return self;
}

/*===========================================================================

	Method: setFFT
	Purpose: Set up display information about the FFT pointed to by
		anFFT.

===========================================================================*/
- setFFT:anFFT
{
NXSize aSize;
float *fp;
int l, L;

	fft = anFFT;

	/* Free the existing bitmap (if there is one) */
	if (bm)
		free(bm);

	/* Calculate size of bitmap in bytes */
	bmWidth = pixelWidth * [fft numberOfWindows];
	bmHeight = 256;
	bml = bmWidth * bmHeight;

	/* Malloc bitmap space */
	bm = (unsigned char *)malloc(bml);
	if (bm == NULL)
		printf("Malloc failed in initFrame:\n");

	/* Clear bitmap */
	bzero(bm, bml);

	/* Size self to the bitmap so that the display is pretty. Update instance variables. */
	[self sizeTo:(float)bmWidth + 50.0:(float)bmHeight + 50.0];
	aSize.width = (float)bmWidth;
	aSize.height = (float)bmHeight;

	/* Set size of last Representation and NXImage */
	[lr setPixelsWide:bmWidth];
	[lr setPixelsHigh:bmHeight];
	[lr setSize:&aSize];
	[image setSize:&aSize];

	[self updateBitmap:self];

	/* Get Max and Min of the FFT for scaling purposes */
	fp = [fft fftData];
	L = [fft numberOfWindows] * [fft binSize] / 2;
	theMin = 10000.0;	/* This should be big enough */
	theMax = -10000.0;	/* And this should be small enough */
	for (l = 0; l < L; l++, fp++)
	{
		if (*fp < theMin)
			theMin = *fp;
		if (*fp > theMax)
			theMax = *fp;
	}

	return self;
}

/*===========================================================================

	Method: fft
	Purpose: return the id of the current fft
	Returns:
		(id) fft instance variable

===========================================================================*/
- fft
{
	return fft;
}


- setTitleView:aView
{
	titleView = aView;
	return self;
}

- titleView
{
	return titleView;

}

/*===========================================================================

	Method: pixelWidth
	Purpose: return the current pixel width
	Returns:
		(int) pixelWidth instance variable.

===========================================================================*/
- (int)pixelWidth
{
	return pixelWidth;
}

/*===========================================================================

	Method: setPixelWidth
	Purpose: Set the pixel width for display.  

===========================================================================*/
- setPixelWidth:(int)aWidth
{
	if (aWidth != pixelWidth)
	{
		pixelWidth = aWidth;
		[self setFFT:fft];
	}
	return self;
}

/*===========================================================================

	Method: displayGrid
	Purpose: return boolean value of instance variable displayGrid
	Returns:
		(BOOL) displayGrid instance variable.

===========================================================================*/
- (BOOL)displayGrid
{
	return displayGrid;
}

/*===========================================================================

	Method: setDisplayGrid
	Purpose: Turn grid display on or off depending on the value of the
		parameter "b".

===========================================================================*/
- setDisplayGrid:(BOOL)b
{
	displayGrid = b;
	[self display];
	return self;
}

/*===========================================================================

	Method: freqInterval
	Purpose: Returns the frequency interval.
	Returns:
		(float) freqInterval instance variable.

===========================================================================*/
- (float)freqInterval
{
	return freqInterval;
}

/*===========================================================================

	Method: setFreqInterval
	Purpose: set the frequency interval of the grid display and display.

===========================================================================*/
- setFreqInterval:(float)x
{
	freqInterval = x;
	[self display];
	return self;
}

/*===========================================================================

	Method: timeInterval
	Purpose: returns the current time interval
	Returns:
		(float) timeInterval instance variable.

===========================================================================*/
- (float)timeInterval
{
	return timeInterval;
}

/*===========================================================================

	Method: setTimeInterval 
	Purpose: set the time interval of the display and re-display.

===========================================================================*/
- setTimeInterval:(float)x
{
	timeInterval = x;
	[self display];
	return self;
}

/*===========================================================================

	Method: scaleLinear
	Purpose: return the boolean value of the instance variable "linear".

===========================================================================*/
- (BOOL)scaleLinear
{
	return linear;
}

/*===========================================================================

	Method: setScaleLinear
	Purpose: to set the instance variable linear

===========================================================================*/
- setScaleLinear:(BOOL)b
{
	linear = b;
	[self updateBitmap:self];
	return self;
}

/*===========================================================================

	The Following Methods return and set instance variables.
	Documentation is unncessary for these methods

===========================================================================*/
- (float)minScale
{
	return minScale;
}

- setMinScale:(float)x
{
	minScale = x;
	[self updateBitmap:self];
	return self;
}

- (float)maxScale
{
	return maxScale;
}

- setMaxScale:(float)x
{
	maxScale = x;
	[self updateBitmap:self];
	return self;
}

- (float)theMin
{
	return theMin;
}

- (float)theMax
{
	return theMax;
}

- (BOOL)negative
{
	return negative;
}

- setNegative:(BOOL)b
{
	theColorSpace = b ? NX_OneIsWhiteColorSpace : NX_OneIsBlackColorSpace;
	[self recache:self];
	return self;
}

@end
