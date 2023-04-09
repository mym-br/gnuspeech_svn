
#import "FFTBrain.h"
#import "FFTView.h"

@implementation FFTBrain //;

- free
{
  printf("FFTBrain - free\n");
  [fft free];

  return [super free];
}

- setUp
{
  /*
   *  This doesn't work if it's put into - init
   */
  [[theMinField cell] setEntryType:NX_FLOATTYPE];
  [theMinField setFloatingPointFormat:YES left:1 right:6];
  [[theMaxField cell] setEntryType:NX_FLOATTYPE];
  [theMaxField setFloatingPointFormat:YES left:1 right:6];

  [[minField cell] setEntryType:NX_FLOATTYPE];
  [[maxField cell] setEntryType:NX_FLOATTYPE];

  /*
   *  It would be nice to be able to take the default values right
   *  out of the interface so that they are easy to change.
   */
  [[freqIntervalField cell] setEntryType:NX_FLOATTYPE];
  [freqIntervalField setFloatingPointFormat:NO left:1 right:3];
  [[timeIntervalField cell] setEntryType:NX_FLOATTYPE];
  [timeIntervalField setFloatingPointFormat:NO left:1 right:3];

  return self;
}

- window
{
  return window;
}

- setFilename:(const char *)aFilename
{
  if (filename)
    free(filename);
  filename = (char *)malloc(strlen(aFilename)+1);
  if (filename)
    strcpy(filename, aFilename);
  else
    printf("malloc() died.\n");
  [window setTitleAsFilename:aFilename];
  return self;
}

- loadFile:(const char *)aFile
{
  const char *ext;

  ext = strrchr(aFile, '.');

  [window setTitle:"Loading..."];
  NXPing();

  if (fft)
    [fft free];

  if (!strcmp(ext, ".fft"))
    {
      fft = [[FFT alloc] initFromFFTfile:aFile];
      if (fft == nil)
	{
	  printf("loading fft failed in FFTBrain.\n");
	  return nil;
	}
      [[scrollView scaleView] setFFT:fft];
      [[scrollView docView] setFFT:fft];
      [self setFilename:aFile];
      
      [self updateControls];
    }
  else
    {
      printf("FFTBrain - loadFile:, loading from .snd\n");
      fft = [[FFT alloc] initFromSoundfile:aFile];
    }

  return self;
}

- printFFT:sender
{
  [scrollView printPSCode:scrollView];

  return self;
}

- updateControls
{
  char buf[32];
  int tmp;

  [windowSlide setIntValue:[fft windowSlide]];
  [hanningWindow setIntValue:[fft hanningWindow]];
  [sampleFreq setFloatValue:(float)[fft samplingRate]/1000.0];
  [timeResolution setFloatValue:1000.0*(float)[fft windowSlide]/(float)[fft samplingRate]];
  [freqResolution setFloatValue:(float)[fft samplingRate]/(float)[fft binSize]];
  tmp = [fft binSize];
  if (tmp==128 || tmp==256 || tmp==512)
    {
      sprintf(buf, "%d", tmp);
      [windowSize setTitle:buf];
    }
  else
    printf("FFTBrain - updateControls, not a supported window size(%d), eh!\n", tmp);

  [timeIntervalField setFloatValue:[[scrollView docView] timeInterval]];
  [freqIntervalField setFloatValue:[[scrollView docView] freqInterval]];

  [theMinField setFloatValue:[[scrollView docView] theMin]];
  [theMaxField setFloatValue:[[scrollView docView] theMax]];

  return self;
}

- takePixelWidth:sender
{
  [[scrollView docView] setPixelWidth:[[sender selectedCell] tag]];
  return self;
}

- (int)pixelWidth
{
  return [[scrollView docView] pixelWidth];
}

/*
 *  This is getting called sometime early with a *large* value
 */

- setPixelWidth:(int)width
{
  char buf[10];
  
  sprintf(buf, "%d", width);
  [pWidth setTitle:buf];

  return [[scrollView docView] setPixelWidth:width];
}

- syncWith:anFFTBrain
{
  if (anFFTBrain != self)
    {
      [self setPixelWidth:[anFFTBrain pixelWidth]];
    }
  /*[self updateControls];*/
  return self;
}

/*- takeAlpha:sender
{
  [[scrollView docView] setA:[sender intValue]];
  return self;
}*/

- takeMaxScale:sender
{
  float f;

  f = [sender floatValue];
  [maxSlider setFloatValue:f];
  [maxField setFloatValue:f];
  [[scrollView docView] setMaxScale:f];

  return self;
}

- takeMinScale:sender
{
  float f;

  f = [sender floatValue];
  [minSlider setFloatValue:f];
  [minField setFloatValue:f];
  [[scrollView docView] setMinScale:f];

  return self;
}

- takeFreqInterval:sender
{
  float i = [sender floatValue];

  if (i < 0.1)
    {
      i = 0.1;
      [sender setFloatValue:i];
    }
  [[scrollView docView] setFreqInterval:i];
  [[scrollView scaleView] setFreqInterval:i];
  return self;
}

- takeTimeInterval:sender
{
  float i = [sender floatValue];

  if (i < 0.01)
    {
      i = 0.01;
      [sender setFloatValue:i];
    }
  [[scrollView docView] setTimeInterval:i];

  return self;
}

- takeGridDisplay:sender
{
  [[scrollView docView] setDisplayGrid:[sender intValue]];

  return self;
}

- takeNegative:sender
{
  [[scrollView docView] setNegative:[sender intValue]];

  return self;
}

- takeScaling:sender
{
  [[scrollView docView] setScaleLinear:([[sender selectedCell] tag]==0)?YES:NO];
  return self;
}

- play:sender
{
  printf("FFTBrain - play:\n");

  printf("%s\n", [[fft sound] isPlayable]?"YES":"NO");
  [[fft sound] play];
  return self;
}

@end //;




@implementation FFTBrain(WindowDelegate) //;

- windowWillClose:sender
{
  [sender setDelegate:nil];
  [self free];
  return self;
}

- windowWillMiniaturize:sender toMiniwindow:miniwindow
{
  [sender setMiniwindowIcon:"defaultappicon"];
  return self;
}

@end //;

