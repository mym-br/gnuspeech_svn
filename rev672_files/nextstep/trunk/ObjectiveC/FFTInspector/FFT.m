
#import <stdio.h>
#import <stdlib.h>
#import "FFT.h"

@implementation FFT

- initFromFFTfile:(const char *)filename
{
  return [self initFromFFTfile:filename headerOnly:NO];
}

- initFromFFTfile:(const char *)filename headerOnly:(BOOL)header
{
  NXStream *FFTStream;

  [super init];

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
   *  Now we're going to load all the data into memory, if necessary.
   */

  /*dataSize = FFTHeader.num_windows * FFTHeader.bin_size / 2;*/
  if (!header)
    {
      data = (float *)malloc([self dataSize]);
      if (data == NULL)
	{
	  printf("Failed to malloc memory for data...");
	  NXCloseMemory(FFTStream, NX_FREEBUFFER);
	  return nil;
	}
      
      if (NXRead(FFTStream, data, [self dataSize]) < [self dataSize])
	{
	  printf("Failed to read in data.\n");
	  free(data);
	  NXCloseMemory(FFTStream, NX_FREEBUFFER);
	  return nil;
	}
    }

  NXCloseMemory(FFTStream, NX_FREEBUFFER);

  return self;
}

- free
{
  printf("FFT - free\n");

  if (data != NULL)
    free(data);

  return [super free];
}

/*
 *  I'm assuming that we'll never have an allocated object that
 *  has invalid data in it...
 */

- (BOOL)hanningWindow
{
  /*
   *  Of course, the lovely numerical recipes translated from fortran
   *  to C use 1 for yes, -1 for no.  Why not just use 32 and 67?!?
   */

  return FFTHeader.hanning==1 ? YES : NO;
}

- (int)windowSlide
{
  return FFTHeader.slide;
}

- (int)numberOfWindows
{
  return FFTHeader.num_windows;
}

- (int)binSize
{
  return FFTHeader.bin_size;
}

- (int)samplingRate
{
  return FFTHeader.sampling_rate;
}

- (char *)comment
{
  return FFTHeader.comment;
}

- (float *)data
{
  return data;
}

- (int)dataSize
{
  /*
   *  A bin size of X will generate X/2 values.
   */
  return FFTHeader.num_windows * FFTHeader.bin_size * sizeof(float) / 2;
}

@end

