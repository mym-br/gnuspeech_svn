
#import "FFTScaleView.h"

/*===========================================================================

	File: FFTScaleView.m
	Original Author: Steven Nygard
	Updated by: Craig-Richard Taube-Schock

===========================================================================*/

@implementation FFTScaleView

/*===========================================================================

	Method: initFrame
	Purpose: initialize the frame of this view.

===========================================================================*/
- initFrame:(const NXRect *)frameRect
{
	[super initFrame:frameRect];

	/* Helvetica was chosen because it looks good on the screen at the
	   chosen sizes.  Times would be better, but it doesn't look as good
	   on the screen. 
	*/
	freqFont = [Font newFont:"Helvetica" size:8.0 matrix:NX_IDENTITYMATRIX];
	if (freqFont == nil)
		printf("FFTScaleView - initFrame:, freqFont not set!\n");

	freqLabelFont = [Font newFont:"Helvetica" size:10.0 matrix:NX_IDENTITYMATRIX];
	if (freqFont == nil)
		printf("FFTScaleView - initFrame:, freqLabelFont not set!\n");

	/* 1 kHz interval */
	freqInterval = 1.0;

	return self;
}


/*===========================================================================

	Method: drawSelf::
	Purpose: To perform the actual drawing of the scale.

===========================================================================*/
- drawSelf:(const NXRect *)rects :(int)rectCount
{
float l, y;
char buf[10];

	/* Clear the view */
	PSsetgray(NX_WHITE);
	PSrectfill(NX_X(&bounds),NX_Y(&bounds),NX_WIDTH(&bounds),NX_HEIGHT(&bounds));

	/* Draw Left hand line in Black */
	PSsetgray(NX_BLACK);
	PSmoveto(49.0, 49.0);
	PSlineto(49.0, 49.0+257.0);
	PSstroke();

	/* If there is an FFT, Draw the frequency scale on the left of the display */
	if (fft)
		for (l=0.0; l<=[fft samplingRate]/2000.0; l+=freqInterval)
		{
			y = 50.0+256.0*l*2000.0/[fft samplingRate];
			PSmoveto(44.0, y);
			PSlineto(49.0, y);
			PSstroke();
			PSmoveto(15.0, y);
			sprintf(buf, "%5.2f", l);
			[freqFont set];
			PSshow(buf);
		}

	return self;
}


/*===========================================================================

	Method: setFFT
	Purpose: set the FFT for this object

===========================================================================*/
- setFFT:anFFT
{
	/* Set new fft and update the display */
	fft = anFFT;
	[self display];

	return self;
}


/*===========================================================================

	Method: setFreqInterval
	Purpose: set the interval (in kHz) of the y axis of the display.
		Default is 1 kHz.

===========================================================================*/
- setFreqInterval:(float)x
{
	/* Set new interval and display */
	freqInterval = x;
	[self display];

	return self;
}
@end
