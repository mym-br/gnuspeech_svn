
#import <objc/Object.h>

#define WINDOW_NONE	0
#define WINDOW_HAN	1
#define WINDOW_KB	2


/*===========================================================================

	Object: FFT
	Purpose: To provide FFT facilities to other objects.

	Author: Craig-Richard Taube-Schock
	Date: Nov. 1, 1993

History:
	Nov. 23, 1993.  Documentation Completed.

===========================================================================*/

@interface FFT:Object
{
	int	filterWindowSize;	/* Size of currentlyCalculated Window */
	int	windowType;		/* Filter window */
	float	windowCoef;		/* And coefficients, if any */
	float	*filterWindow;		/* The actual table */

	int	windowSlide;		/* Slide */
	int	numberOfWindows;	/* Number of windows in total */
	int	binSize;		/* Window Size */
	int	samplingRate;		/* sampling Rate */

	int	soundDataSize;		/* Number of samples in Sound data */
	float	*soundData;		/* Sound data */

	int	dirtybit;		/* Does FFT data match settings above? */
	int	fftDataSize;		/* Data size for FFT */
	float	*fftData;		/* fftData */
	float	maxFFTData;		/* Largest fft output (for Scaling purposes) */

	char	*name;			/* Identification */
}

- init;
- free;

- doAnalysis;
- doAnalysisToFile: (char *) file;

- preparePackedWindow:(float *) dataWindow fromIndex: (int) soundIndex;

- (int)windowSlide;
- (int)numberOfWindows;
- (int)binSize;
- (int)samplingRate;
- (int)soundDataSize;
- (float *)soundData;
- (int)fftDataSize;
- (float *)fftData;
- (int) windowType;
- (float) windowCoef;
- (float) maxFFTData;
- (char *) FFTName;

- setWindowNone;
- setWindowHanning;
- setWindowKB: (float) alpha;

- setFFTName: (char *) string;
- setWindowSlide:(int)x;
- setBinSize:(int)x;
- setSamplingRate: (int) rate;
- setSoundData: (short *) newData dataSize: (int) size;

@end
