
#import <stdio.h>
#import <stdlib.h>
#import <strings.h>
#import "FFT.h"

@implementation FFT

- initFromFFTfile:(const char *)filename /*headerOnly:(BOOL)header*/
{
  struct _FFTheader FFTHeader;

  [super init];

  snd = nil;

  FFTStream = NXMapFile(filename, NX_READONLY);
  if (FFTStream == NULL)
    {
      fprintf(stderr, "Couldn't map file.\n");
      return nil;
    }

  if (NXRead(FFTStream, &FFTHeader, sizeof(FFTHeader)) != sizeof(FFTHeader))
    {
      fprintf(stderr, "Couldn't read all of the header.\n");
      NXCloseMemory(FFTStream, NX_FREEBUFFER);
      return nil;
    }
  if (FFTHeader.anaMagic != ANA_MAGIC)
    {
      fprintf(stderr, "This is not an FFT file.\n");
      NXCloseMemory(FFTStream, NX_FREEBUFFER);
      return nil;
    }

  /*
   *  Of course, the lovely numerical recipes translated from fortran
   *  to C use 1 for yes, -1 for no.  Why not just use 32 and 67?!?
   */
  hanningWindow = FFTHeader.hanning==1 ? YES : NO;
  windowSlide = FFTHeader.slide;
  numberOfWindows = FFTHeader.num_windows;
  binSize = FFTHeader.bin_size;
  samplingRate = FFTHeader.sampling_rate;
  /* I sure hope the comment is null terminated. */
  comment = (char *)malloc(strlen(FFTHeader.comment)+1);
  strcpy(comment, FFTHeader.comment);
  /*
   *  A bin size of X will generate X/2 values.
   */
  dataSize = FFTHeader.num_windows * FFTHeader.bin_size * sizeof(float) / 2;

  /*
   *  I'm trying to lazily load the data so that this can be used
   *  cleanly from the FFTInspector bundle...
   */
  data = NULL;

  return self;
}

/*----------------------------------------------------------------------*/

- free
{
  printf("FFT - free\n");

  if (data != NULL)
    free(data);
  if (FFTStream)
    NXCloseMemory(FFTStream, NX_FREEBUFFER);

  return [super free];
}

/*----------------------------------------------------------------------*/

/*
 *  I'm assuming that we'll never have an allocated object that
 *  has invalid data in it...
 */

/*----------------------------------------------------------------------*/

- (BOOL)hanningWindow
{
  return hanningWindow;
}

/*----------------------------------------------------------------------*/

- (int)windowSlide
{
  return windowSlide;
}

/*----------------------------------------------------------------------*/

- (int)numberOfWindows
{
  return numberOfWindows;
}

/*----------------------------------------------------------------------*/

- (int)binSize
{
  return binSize;
}

/*----------------------------------------------------------------------*/

- (int)samplingRate
{
  return samplingRate;
}

/*----------------------------------------------------------------------*/

- (char *)comment
{
  return comment;
}

/*----------------------------------------------------------------------*/

- (int)dataSize
{
  return dataSize;
}

/*----------------------------------------------------------------------*/

- (float *)data
{
  /*
   *  We lazily load the data
   */

  if (data == NULL && FFTStream != NULL)
    {
      data = (float *)malloc([self dataSize]);
      if (data == NULL)
	{
	  printf("Failed to malloc memory for data...");
	  NXCloseMemory(FFTStream, NX_FREEBUFFER);
	  return NULL;
	}
      
      if (NXRead(FFTStream, data, [self dataSize]) < [self dataSize])
	{
	  printf("Failed to read in data.\n");
	  free(data);
	  NXCloseMemory(FFTStream, NX_FREEBUFFER);
	  return NULL;
	}
      NXCloseMemory(FFTStream, NX_FREEBUFFER);
      FFTStream = NULL;
    }

  return data;
}

/*----------------------------------------------------------------------*/

-  initFromSoundfile:(const char *)filename
{
  char buf[256];

  originalSound = [[Sound alloc] initFromSoundfile:filename];
//  while ([originalSound status]!=NX_SoundStopped)
//    printf("%d\n", [originalSound status]);
//  [originalSound play];
//  while ([originalSound status]!=NX_SoundStopped)
//    printf("%d\n", [originalSound status]);
//  [originalSound play];
  gets(buf);
  snd = [Sound alloc];
  (void)[snd copySound:originalSound];
 if([snd convertToFormat:SND_FORMAT_LINEAR_16 samplingRate:(double)11025 channelCount:1])
    {
      printf("Error converting sound file.\n");
      return nil;
    }
  hanningWindow = YES;
  windowSlide = 64;
  binSize = 512;
  samplingRate = (int)[snd samplingRate];

  /*int numberOfWindows;
  char *comment;
  int dataSize;
  float *data;*/

  return nil;
}

/*----------------------------------------------------------------------*/

- sound
{
  return originalSound;
}

/*----------------------------------------------------------------------*/

- setHanningWindow:(BOOL)b
{
  if (b != hanningWindow)
    hanningWindow = b;
  /* set flag... */
  return self;
}

/*----------------------------------------------------------------------*/

- setWindowSlide:(int)x
{
  if (x != windowSlide)
    windowSlide = x;
  /* set flag... */
  return self;
}

/*----------------------------------------------------------------------*/

- setBinSize:(int)x
{
  if (x != binSize)
    binSize = x;
  /* set flag... */
  return self;
}

@end
