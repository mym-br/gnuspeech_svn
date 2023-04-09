
#import "FFTTitleView.h"
#import "FFT.h"

/*===========================================================================

	File: FFTTitleView.m
	Author: Craig-Richard Taube-Schock

===========================================================================*/

@implementation FFTTitleView

/*===========================================================================

	Method: initFrame:
	Purpose: initialize the frame and set up Fonts.

===========================================================================*/
- initFrame:(const NXRect *)frameRect
{
	[super initFrame:frameRect];

	/* I prefer Times-Roman myself.  Big enough to look good on the screen. */
	titleFont = [Font newFont:"Times-Roman" size:12.0 matrix:NX_IDENTITYMATRIX];
	if (titleFont == nil)
		printf("FFTTitleView - initFrame:, TitleFont not set!\n");

	return self;
}

/*===========================================================================

	Method: drawSelf
	Purpose: draw title information

===========================================================================*/
- drawSelf:(const NXRect *)rects :(int)rectCount
{
char buffer[1024];
char buf1[256], buf2[256], buf3[256];

	/* Clear out display area */
	PSsetgray(NX_WHITE);
	PSrectfill(NX_X(&bounds),NX_Y(&bounds),NX_WIDTH(&bounds),NX_HEIGHT(&bounds));
	PSstroke();

	/* If an fft has been set, display fft information */
	if (fft)
	{
		bzero(buf1, 256);
		bzero(buf2, 256);
		bzero(buf3, 256);

		PSsetgray(NX_BLACK);
		[titleFont set];

		bzero(buffer, 1024);
		sprintf(buffer,"File: %s", [fft FFTName]);
		PSmoveto(10.0, 30.0);
		PSshow(buffer);

		sprintf(buf1,"Sampling Rate: %d Hz", [fft samplingRate]);

		switch([fft windowType])
		{
			case WINDOW_NONE: 
				sprintf(buf2,"Window: Square");
				break;

			case WINDOW_HAN: 
				sprintf(buf2,"Window: Hanning");
				break;

			case WINDOW_KB: 
				sprintf(buf2,"Window: Kaiser-Bessel (%.2f)", [fft windowCoef]);
				break;
		}

		sprintf(buf3, "Window Slide: %d", [fft windowSlide]);
		sprintf(buffer, "%s    %s    %s", buf1, buf2, buf3);

		PSmoveto(10.0, 15.0);
		PSshow(buffer);


		PSstroke();
	}

	return self;
}

/*===========================================================================

	Method: setFFT
	Purpose: set the FFT pointer.  An fft object must be queried for 
		display information (ie. name of fft, etc).

===========================================================================*/
- setFFT:anFFT
{

	fft = anFFT;
	[self display];
	return self;

}

@end
