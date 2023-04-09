
#import <objc/Object.h>
#import <soundkit/Sound.h>
#import "structs.h"

@interface FFT:Object
{
  BOOL hanningWindow;
  int windowSlide;
  int numberOfWindows;
  int binSize;
  int samplingRate;
  char *comment;
  int dataSize;
  float *data;

  Sound *originalSound;
  Sound *snd;

  NXStream *FFTStream;
}

- initFromFFTfile:(const char *)filename;
- free;

- (BOOL)hanningWindow;
- (int)windowSlide;
- (int)numberOfWindows;
- (int)binSize;
- (int)samplingRate;
- (char *)comment;
- (int)dataSize;
- (float *)data;

- initFromSoundfile:(const char *)filename;
- sound;

- setHanningWindow:(BOOL)b;
- setWindowSlide:(int)x;
- setBinSize:(int)x;

@end
