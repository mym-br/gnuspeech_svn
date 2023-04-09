
#import "FFTScaleView.h"

@implementation FFTScaleView

- initFrame:(const NXRect *)frameRect
{
  [super initFrame:frameRect];

  freqFont = [Font newFont:"Helvetica" size:8.0 matrix:NX_IDENTITYMATRIX];
  if (freqFont == nil)
    printf("FFTScaleView - initFrame:, freqFont not set!\n");

  freqLabelFont = [Font newFont:"Helvetica" size:10.0 matrix:NX_IDENTITYMATRIX];
  if (freqFont == nil)
    printf("FFTScaleView - initFrame:, freqLabelFont not set!\n");

  freqInterval = 1.0;

  return self;
}

- drawSelf:(const NXRect *)rects :(int)rectCount
{
  float l, y;
  char buf[10];

  PSsetgray(NX_WHITE);
  PSrectfill(NX_X(&bounds),NX_Y(&bounds),NX_WIDTH(&bounds),NX_HEIGHT(&bounds));

  PSsetgray(NX_BLACK);
  PSmoveto(49.0, 49.0);
  PSlineto(49.0, 49.0+257.0);
  PSstroke();

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

- setFFT:anFFT
{
  fft = anFFT;
  [self display];
  return self;
}

- setFreqInterval:(float)x
{
  freqInterval = x;
  [self display];

  return self;
}
@end
