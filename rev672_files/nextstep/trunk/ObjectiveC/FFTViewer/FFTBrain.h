
#import <appkit/appkit.h>
#import "FFT.h"
#import "FFTScrollView.h"

@interface FFTBrain:Object //;
{
#ifdef NIBISREALLYSTUPID
  id scrollView;
#endif
  FFTScrollView *scrollView;
  id window;
  char *filename;
  FFT *fft;

  /* These are id's of the fancy controls */
  id sampleFreq;
  id hanningWindow;
  id windowSlide;
  id timeResolution;
  id freqResolution;
  id windowSize;

  /* Don't call this pixelWidth -- it just doesn't work! */
  id pWidth;

  id minSlider;
  id maxSlider;
  id minField;
  id maxField;
  id theMinField;
  id theMaxField;

  id freqIntervalField;
  id timeIntervalField;
}

- free;

- setUp;
- window;
/*- windowWillClose:sender;*/

- setFilename:(const char *)aFilename;
/*- saveAs:sender;*/
/*- save:sender;*/
- loadFile:(const char *)aFile;
- printFFT:sender;

- updateControls;
- takePixelWidth:sender;
- (int)pixelWidth;
- setPixelWidth:(int)width;

- syncWith:anFFTBrain;

- takeMaxScale:sender;
- takeMinScale:sender;
- takeFreqInterval:sender;
- takeTimeInterval:sender;
- takeGridDisplay:sender;
- takeNegative:sender;
- takeScaling:sender;

- play:sender;

@end

@interface FFTBrain(WindowDelegate) //;
- windowWillClose:sender;
- windowWillMiniaturize:sender toMiniwindow:miniwindow;
@end //;
