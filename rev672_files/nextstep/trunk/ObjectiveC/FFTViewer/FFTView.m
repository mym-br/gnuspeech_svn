
#import <math.h>
#import "FFTView.h"

@implementation FFTView

- initFrame:(const NXRect *)frameRect
{
	[super initFrame:frameRect];

	image = [[NXImage alloc] initSize:&frameRect->size];
	if (![image useDrawMethod:@selector(theDrawing:) inObject :self])
		printf("[image useDrawMethod:inObject:] failed.\n");

	lr = [image lastRepresentation];
	[lr setNumColors:1];
	[lr setAlpha:NO];
	[lr setBitsPerSample:8];

	[self setFlipped:NO];

	timeFont = [Font newFont:"Helvetica" size:8.0 matrix:NX_IDENTITYMATRIX];
	if (timeFont == nil)
		printf("FFTView - initFrame: font junk failed.\n");

	theColorSpace = NX_OneIsBlackColorSpace;
	negative = NO;
	linear = YES;

	pixelWidth = 2;

	displayGrid = YES;
	timeInterval = 0.25;
	freqInterval = 1.0;

	minScale = 0.0;
	maxScale = 1.0;
	theMin = theMax = 0.0;

	return self;
}

- drawSelf:(const NXRect *)rects :(int)rectCount
{
NXPoint myPoint = {0.0, 49.0};
float l, t, x, y;
char buf[20];

 /* clear the view */
	PSsetgray(NX_WHITE);
	PSrectfill(NX_X(rects), NX_Y(rects), NX_WIDTH(rects), NX_HEIGHT(rects));

 /*
  * The compositing is definately displaying the image one pixel higher than
  * it should! 
  */

 /*
  * HEAP HEAP HEAP HEAP HEAP HEAP HEAP HEAP HEAP HEAP HEAP HEAP HEAP 
  *
  * If the coordinates are flipped, drawing from point 0.0, 0.0 won't show
  * anything in the view.  You must set the y coordinate to the height. 
  * Flipped coordinates don't seem to work with the image anyways, it's still
  * upside down. 
  *
  * HEAP HEAP HEAP HEAP HEAP HEAP HEAP HEAP HEAP HEAP HEAP HEAP HEAP 
  */

 /*
  * if ([image composite:NX_SOVER toPoint:&myPoint] == nil)
  * printf("compositing failed(%d).\n",i++); 
  */
	myPoint.x = NX_X(rects);
	if ([image composite:NX_SOVER fromRect:rects toPoint:&myPoint] == nil)
		printf("compositing failed.\n");

 /*
  * Let's not be foolish here and overwrite the bottom row of the FFT. Why
  * even draw at all?  To erase underneath the test, dummy! 
  */
	PSsetgray(NX_WHITE);
	PSrectfill(0.0, 0.0, NX_WIDTH(&bounds), 49.0);

	PSsetgray(NX_BLACK);
	PSmoveto(0.0, 49.0);
	PSlineto(NX_WIDTH(&bounds), 49.0);
	PSstroke();

	PSsetgray(NX_BLACK);
	[timeFont set];
	t = 0.0;
	x = 0.0;
	y = displayGrid ? NX_HEIGHT(&bounds) : 49.0;
	while (x < [fft numberOfWindows] * pixelWidth)
	{
		x = t / [fft windowSlide] * [fft samplingRate] * pixelWidth;
		if (x > NX_X(rects) && x < NX_X(rects) + NX_WIDTH(rects))
		{
			PSmoveto(x, 44.0);
		/* PSlineto(x, 49.0); */
		/* PSlineto(x, NX_HEIGHT(&bounds)); */
			PSlineto(x, y);
			PSstroke();
		}
		PSmoveto(x, 30.0);
		sprintf(buf, "%.2f", t);
		PSshow(buf);
		t += timeInterval;
	}

	if (fft && displayGrid)
		for (l = 0.0; l <= [fft samplingRate] / 2000.0; l += freqInterval)
		{
			y = 50.0 + 256.0 * l * 2000.0 / [fft samplingRate];
			PSmoveto(NX_X(rects), y);
			PSlineto(NX_X(rects) + NX_WIDTH(rects), y);
			PSstroke();
		}

	return self;
}

- free
{
	printf("FFTView - free\n");

	if (bm)
		free(bm);

	return[super free];
}

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
	bzero(bm, bml);

	fp = [fft data];
	if (linear)
	{
		for (l = 0; l < [fft numberOfWindows]; l++)
		{
		/* should this be *254? */
			p = bm + 255 * bmWidth + pixelWidth * l;
			for (m = 0; m < floatsInWindow; m++)
			{
				ftmp = (*fp - minScale) / scaleWidth;
				if (ftmp > 1.0)
					ftmp = 1.0;
				if (ftmp < 0.0)
					ftmp = 0.0;
				g = ftmp * 255;

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
	/*
	 * Insert your own "Log" scaling code here.  The FFT values are
	 * floats. theMin and theMax track min/max values of all the FFT
	 * data. Zero values will be white. 
	 */
	{
		float               maxLn = (float)log10((double)maxScale - (double)minScale + 1.0);

		for (l = 0; l < [fft numberOfWindows]; l++)
		{
		/* should this be *254? */
			p = bm + 255 * bmWidth + pixelWidth * l;
			for (m = 0; m < floatsInWindow; m++)
			{
				ftmp = (float)log10((double)(*fp - minScale + 1.0)) / maxLn;
				if (ftmp > 1.0)
					ftmp = 1.0;
				if (ftmp < 0.0)
					ftmp = 0.0;
				g = ftmp * 255;

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

	[image recache];
	[self display];

	return self;
}

- recache:sender
{
	[image recache];
	[self display];

	return self;
}

- setFFT:anFFT
{
NXSize aSize;
float *fp;
int l, L;

	fft = anFFT;
	if (bm)
		free(bm);

	bmWidth = pixelWidth * [fft numberOfWindows];
	bmHeight = 256;
	bml = bmWidth * bmHeight;

	bm = (unsigned char *)malloc(bml);
	if (bm == NULL)
		printf("Malloc failed in initFrame:\n");
	bzero(bm, bml);
	[self sizeTo:(float)bmWidth + 50.0:(float)bmHeight + 50.0];
	aSize.width = (float)bmWidth;
	aSize.height = (float)bmHeight;

	[lr setPixelsWide:bmWidth];
	[lr setPixelsHigh:bmHeight];
	[lr setSize:&aSize];
	[image setSize:&aSize];

	[self updateBitmap:self];

	fp = [fft data];
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

- (int)pixelWidth
{
	return pixelWidth;
}

- setPixelWidth:(int)aWidth
{
	if (aWidth != pixelWidth)
	{
		pixelWidth = aWidth;
		[self setFFT:fft];
	}
	return self;
}

- (BOOL)displayGrid
{
	return displayGrid;
}

- setDisplayGrid:(BOOL)b
{
	displayGrid = b;
	[self display];
	return self;
}

- (float)freqInterval
{
	return freqInterval;
}

- setFreqInterval:(float)x
{
	freqInterval = x;
	[self display];
	return self;
}

- (float)timeInterval
{
	return timeInterval;
}

- setTimeInterval:(float)x
{
	timeInterval = x;
	[self display];
	return self;
}

- (BOOL)scaleLinear
{
	return linear;
}

- setScaleLinear:(BOOL)b
{
	linear = b;
	[self updateBitmap:self];
	return self;
}

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
