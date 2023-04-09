
#import "FFTInspector.h"
#import "FFT.h"

static id fftInspector = nil;

@implementation FFTInspector

+ new
{
  if (fftInspector == nil)
    {
      char path[MAXPATHLEN+1];
      NXBundle *bundle = [NXBundle bundleForClass:self];
      
      self = fftInspector = [super new];
      if ([bundle getPath:path forResource:"FFTInspector" ofType:"nib"])
	{
	  [NXApp loadNibFile:path owner:fftInspector];
	}
      else
	{
	  fprintf (stderr, "Couldn't load FFTInspector.nib\n");
	  fftInspector = nil;
	}
    }

  return fftInspector;
}

- revert:sender
{
  char fullPath[MAXPATHLEN+1];
  char buf[64];
  FFT *fft;
  /*
   *       Window Size: 512
   *  Freq. Resolution: 21.533203 Hz
   *      Window Slide: 64
   *   Time Resolution: 5.804989 ms
   *    Hanning Window: YES
   *     Sampling Rate: 11025.000 Hz
   *           Windows: 42?
   *         Data Size: 11589? bytes
   *  _comment_
   */

  [self selectionPathsInto:fullPath separator:'\0'];

  if (fft=[[FFT alloc] initFromFFTfile:fullPath headerOnly:YES])
    {
      [[entryMatrix selectCellWithTag:0] setIntValue:[fft binSize]];
      sprintf(buf, "%f Hz", (float)[fft samplingRate]/(float)[fft binSize]);
      [[entryMatrix selectCellWithTag:1] setStringValue:buf];
      [[entryMatrix selectCellWithTag:2] setIntValue:[fft windowSlide]];
      sprintf(buf, "%f ms", 1000.0*(float)[fft windowSlide]/(float)[fft samplingRate]);
      [[entryMatrix selectCellWithTag:3] setStringValue:buf];
      [[entryMatrix selectCellWithTag:4] setStringValue:[fft hanningWindow]?"YES":"NO"];
      sprintf(buf, "%d Hz", [fft samplingRate]);
      [[entryMatrix selectCellWithTag:5] setStringValue:buf];
      [[entryMatrix selectCellWithTag:6] setIntValue:[fft numberOfWindows]];
      sprintf(buf, "%d bytes", [fft dataSize]);
      [[entryMatrix selectCellWithTag:7] setStringValue:buf];
      [fft free];
    }
  else
    {
      int l;

      for (l=0; l<8; l++)
	[[entryMatrix selectCellWithTag:l] setStringValue:""];
    }

  return [super revert:sender];
}

@end
