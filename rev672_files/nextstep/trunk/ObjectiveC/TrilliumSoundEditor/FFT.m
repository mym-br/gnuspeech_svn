
#import "FFT.h"
#import "structs.h"
#import <stdio.h>
#import <stdlib.h>
#import <string.h>
#import <mach/boolean.h>
#import <math.h>

/*===========================================================================

	File: FFT.m
	Author: Craig-Richard Taube-Schock

===========================================================================*/

/*===========================================================================

	Function: four1()
	Purpose: The fft function.

	PLEASE NOTE:  This routine has been converted from FORTRAN (ARGH).
		Buffers	are indexed from 1 and NOT 0.  Remember this when
		you are	preparing your windows!

	LOOKING FOR NEW FFT CODE!!

===========================================================================*/
#define SWAP(a,b) tempr = (a); (a)=(b); (b)=tempr

void four1(data, nn, isign)
float *data;
int nn, isign;
{
int n,mmax,m,j,istep,i;
double wtemp,wr,wpr,wpi,wi,theta;
float tempr, tempi;

	n = nn << 1;
	j = 1;

	for(i = 1; i<n; i+=2)
	{
		if (j>i) 
		{
			SWAP(data[j],data[i]);
			SWAP(data[j+1],data[i+1]);
		}
		m = n >> 1;

		while(m >= 2 && j > m)
		{
			j -= m;
			m >>= 1;
		}
		j += m;
	}

	mmax = 2;
	while(n>mmax)
	{
		istep = 2*mmax;
		theta = 6.28318530717959/(isign*mmax);
		wtemp = sin(0.5*theta);
		wpr = -2.0*wtemp*wtemp;
		wpi = sin(theta);
		wr = 1.0;
		wi = 0.0;

		for(m=1;m<mmax;m+=2)
		{
			for(i=m;i<=n;i+=istep)
			{
				j = i+mmax;
				tempr = wr*data[j]-wi*data[j+1];
				tempi = wr*data[j+1]+wi*data[j];
				data[j]=data[i]-tempr;
				data[j+1] = data[i+1]-tempi;
				data[i] += tempr;
				data[i+1] += tempi;
			}
			wr = (wtemp=wr)*wpr-wi*wpi+wr;
			wi = wi*wpr+wtemp*wpi+wi;
		}
		mmax = istep;
	}
}



@implementation FFT

/*===========================================================================

	Method: init
	Purpose: Initialize all instance variables after instantiation of an
		FFT object.

===========================================================================*/
- init
{
	/* Filter window variables */
	filterWindowSize = 0;
	windowType = WINDOW_NONE;
	windowCoef = 0.0;
	filterWindow = NULL;

	/* FFT Variables */
	windowSlide = 0;
	numberOfWindows = 0;
	binSize = 0;
	samplingRate = 0;

	/* Sound Data Variables */
	soundDataSize = 0;
	soundData = NULL;

	/* Misc variables */
	dirtybit = 0;
	fftDataSize = 0;
	fftData = NULL;

	/* Display Information Variables */
	name = NULL;

	return self;
}

/*===========================================================================

	Method: free
	Purpose: Free all malloced data space.

===========================================================================*/
- free
{
	/* Free all malloced data, if any */
	if (soundData) free(soundData);
	if (fftData) free(fftData);
	if (filterWindow) free(filterWindow);

	[super free];
	return self; 
}

/*===========================================================================

	Method: doAnalysis
	Purpose: Call this function to initiate an analysis.  To get an 
		FFT, external objects should call this function.

===========================================================================*/
- doAnalysis
{
float *results, *dataWindow;
double realCoef, imagCoef;
int fftSize = 0 , soundIndex = 0, resultIndex = 0, i;


	if (filterWindowSize == 0) [self setWindowNone];

	/* Clear any old FFT data */
	if (fftData) free(fftData);

	/* Calculate size of FFT data space and malloc. */
	numberOfWindows = soundDataSize/(windowSlide*2);
	fftSize = (binSize)*numberOfWindows * sizeof(float);
	fftData = results = (float *) malloc (fftSize);

	/* FFT takes an array of real and imaginary numbers.  Malloc space. */
	dataWindow = (float *) malloc(sizeof(float)*2*binSize + 100);	/* NOTE: +100 is a Kludge */

	/* maxFFTData used for scaling.  Hold the max output from the FFT */
	maxFFTData = 0.0;

	/* Traverse through the sound data */
	while(soundIndex<(soundDataSize/2))
	{
		/* Prepare a window for FFT */
		[self preparePackedWindow:dataWindow fromIndex: soundIndex];

		/* FFT this window */
		four1(dataWindow, binSize, 1);

		/* Calculate the hypotenuse (power) for each bin */
		for (i = 1 ; i<binSize; i+=2)
		{
			/* Pythagoras theorem */
			realCoef = (double) dataWindow[i]*dataWindow[i];
			imagCoef = (double) dataWindow[i+1]*dataWindow[i+1];
			results[resultIndex] = (float) sqrt(realCoef+imagCoef);

			/* Check output and record if maximum value */
			if (results[resultIndex]>maxFFTData)
				maxFFTData = results[resultIndex];

			resultIndex++;
		}

		/* Slide window */
		soundIndex+=(windowSlide);
	}

	/* Free window space */
	free(dataWindow);

	return self; 
}

/*===========================================================================

	Method: doAnalysisToFile:
	Purpose: This method performs and fft on sound data and saves it 
		to an FFT file. 

===========================================================================*/
- doAnalysisToFile: (char *) file;
{
FILE *fp;
float *results, *dataWindow;
double realCoef, imagCoef;
struct _FFTheader FFTHeader;
int fftSize = 0 , soundIndex = 0, resultIndex = 0, i;

	/* Open output file. Return nil if error */
	fp = fopen (file, "w");
	if (!fp)
	{
		return nil;
	}

	if (filterWindowSize == 0) [self setWindowNone];

	/* Clear header for FFT file */
	bzero(&FFTHeader, sizeof (struct _FFTheader));

	/* Calculate size of FFT data space and malloc. */
	numberOfWindows = soundDataSize/(windowSlide*2);
	fftSize = (binSize/2)*numberOfWindows * sizeof(float);
	fftData = results = (float *) malloc (fftSize);

	/* FFT header defined in "structs.h" */
	FFTHeader.anaMagic = ANA_MAGIC;
	FFTHeader.hanning = windowType;
	FFTHeader.slide = windowSlide;
	FFTHeader.bin_size = binSize;
	FFTHeader.num_windows = numberOfWindows;
	FFTHeader.sampling_rate = samplingRate;
	fwrite(&FFTHeader, sizeof (struct _FFTheader), 1, fp);

	/* FFT takes an array of real and imaginary numbers.  Malloc space. */
	dataWindow = (float *) malloc(sizeof(float)*2*binSize + 100);	/* NOTE: +100 is a Kludge */

	/* Traverse sound data */
	while(soundIndex<(soundDataSize/2))
	{
		/* Prepare a window for FFT */
		[self preparePackedWindow:dataWindow fromIndex: soundIndex];

		/* Do the FFT */
		four1(dataWindow, binSize, 1);

		/* Calculate the hypotenuse (power) for each bin */
		for (i = 1 ; i<binSize; i+=2)
		{
			realCoef = (double) dataWindow[i]*dataWindow[i];
			imagCoef = (double) dataWindow[i+1]*dataWindow[i+1];

			results[resultIndex++] = (float) sqrt(realCoef+imagCoef);
		}

		/* Slide the window */
		soundIndex+=(windowSlide);
	}

	/* Write the results to file and close */
	fwrite(results, 1, fftSize, fp);
	fclose(fp);

	free(dataWindow);

	return self; 
}

/*===========================================================================

	Method: preparePackedWindow: fromIndex:
	Purpose: Prepare a window for FFT.  Unfortunately, the window packing
		wasn't working propperly so currently windows are not packed.
		This will be corrected in the next version.

	Parameters:
		(float *) dataWindow: Pointer to array of real and imaginary
			numbers.
		(int) soundIndex: Index into the sound data space.

===========================================================================*/
- preparePackedWindow:(float *) dataWindow fromIndex: (int) soundIndex
{
int i, index1, index2;

	/* Clear the data window */
	bzero(dataWindow, sizeof(float)*binSize);

	index1 = soundIndex;
	index2 = soundIndex+windowSlide;

	for (i = 1; i<=binSize*2; i+=2)
	{
		/* Real space */
		if (index1>(soundDataSize/2))
			dataWindow[i] = 0.0;
		else
			dataWindow[i] = soundData[index1++]*filterWindow[i/2];

		/* Imaginary Space */
		if (index2>(soundDataSize/2))
			dataWindow[i+1] = 0.0;
		else
//			dataWindow[i+1] = soundData[index2++]*filterWindow[i/2];
			dataWindow[i+1] = 0.0;

	}
	return self;
}

/*===========================================================================

	Method: windowSlide
	Purpose: Return the current window slide.
	Returns: (int) windowSlide instance variable.

===========================================================================*/
- (int)windowSlide
{
	return windowSlide; 
}

/*===========================================================================

	Method: numberOfWindows
	Purpose: Returns the calculated number of windows for the current
		sound data/FFT data
	Returns: (int) numberOfWindows instance variable.

===========================================================================*/
- (int)numberOfWindows
{
	return numberOfWindows; 
}

/*===========================================================================

	Method: binSize
	Purpose: Returns the number of samples per window for the current
		sound/FFT data.  

	NOTE: The name of this method is somewhat confusing but remains
	for historical reasons to maintain compatibility with other objects.  

	Returns:(int) binSize instance variable.

===========================================================================*/
- (int)binSize
{
	return binSize;
}

/*===========================================================================

	Method: samplingRate
	Purpose: Return sampling rate of the current sound data.
	Returns: samplingRate instance variable.

	NOTE: The sound object's sampling rate is stored as a double.
		Future versions of this object may use double as well.

===========================================================================*/
- (int)samplingRate
{
	return samplingRate;
}

/*===========================================================================

	Method: soundDataSize
	Purpose: Return the number of bytes in the current sound data.
	Returns: (int) soundDataSize instance variable.

===========================================================================*/
- (int)soundDataSize
{
	return soundDataSize; 
}

/*===========================================================================

	Method: soundData
	Purpose: return a pointer to the sound data.
	Returns: (float *) soundData.

	NOTE:  The data stored in this buffer should NOT be mucked with.
		Perhaps this function should return a (const float *).
		Future versions.

===========================================================================*/
- (float *)soundData
{
	return soundData; 
}

/*===========================================================================

	Method: fftDataSize
	Purpose: Return the number of bytes in the FFT data buffer.
	Returns: (int) fftDataSize instance variable.

===========================================================================*/
- (int)fftDataSize
{
	return fftDataSize;
}

/*===========================================================================

	Method: fftData
	Purpose: Return a pointer to the FFT data.
	Returns: (float *) fftData

	NOTE:  The data stored in this buffer should NOT be mucked with.
		Perhaps this function should return a (const float *).
		Future versions.

===========================================================================*/
- (float *)fftData
{
	return fftData;
}

/*===========================================================================

	Method: windowType
	Purpose: Returns the type of window used in the FFT.
	Returns: (int) windowType instance variable.

	NOTE: Window Types are defined in "FFT.h". They are currently:
		WINDOW_NONE	0
		WINDOW_HAN	1
		WINDOW_KB	2

===========================================================================*/
- (int) windowType
{
	return windowType;
}

/*===========================================================================

	Method: windowCoef
	Purpose: Return the window Coefficient
	Returns: (float) windowCoef.

	NOTE: Currently, the coefficient is only applicable to the 
		Kaiser-Bessel window function.

===========================================================================*/
- (float) windowCoef
{
	return windowCoef;
}

/*===========================================================================

	Method: maxFFTData
	Purpose: The maximum value computed by the FFT. Used generally for
		scaling purposes.
	Returns: (float) maxFFTData

===========================================================================*/
- (float) maxFFTData
{
	return maxFFTData;
}

/*===========================================================================

	Method: setWindowNone.
	Purpose: To set a square window.

	NOTE: No window for for FFT is really a square window.  For
		implementational convenience, a window of 1.0's is generated.

===========================================================================*/
- setWindowNone
{
int i;

	/* Clear the existing filter window, if it exists. */
	if (filterWindow) free(filterWindow);

	/* Calculate a new FFT window */
	filterWindow = (float *) malloc(binSize*sizeof(float));
	filterWindowSize = binSize;

	/* Fill the window with 1.0's */
	for (i = 0; i<binSize; i++)
	{
		filterWindow[i] = 1.0;
//		printf("1.0\n");
	}

	/* Update instance variables */
	windowType = WINDOW_NONE;
	windowCoef = 0.0;

	return self; 
}

#define PI 3.14159265358979

/*===========================================================================

	Method: setWindowHanning
	Purpose: Calculate a Hanning window for FFT

===========================================================================*/
- setWindowHanning
{
int i;
float temp;

	/* Clear the existing filter window, if it exists. */
	if (filterWindow) free(filterWindow);

	/* Calculate a new FFT window */
	filterWindow = (float *) malloc(binSize*sizeof(float));
	filterWindowSize = binSize;

	/* Calculate window */
	for (i = 0; i<binSize; i++)
	{
		temp = 0.5*(1-cos(2.0*PI*(float)i/(float)(binSize-1)));
		if (temp<0.0) temp = -temp;
		filterWindow[i] = temp;
//		printf("%f\n", temp);
	}

	/* Update instance variables */
	windowType = WINDOW_HAN;
	windowCoef = 0.0;

	return self; 
}

extern void init_KB_coefs();

/*===========================================================================

	Method: setWindowKB
	Purpose: Calculate a Kaiser-Bessel window for FFT
	Parameters: (float) alpha.  The alpha for KB function.

===========================================================================*/
- setWindowKB: (float) alpha
{
int i, j = 0;
double *KB_coefs;

	/* Clear the existing filter window, if it exists. */
	if (filterWindow) free(filterWindow);

	/* Calculate a new FFT window */
	filterWindow = (float *) malloc(binSize*sizeof(float));
	filterWindowSize = binSize;

	/* Malloc temporary space for window calculation. */
	KB_coefs = (double *) malloc(sizeof(double)*binSize/2);

	/* Call function in "kb_window.c" to calculate window */
	init_KB_coefs(binSize/2, alpha, KB_coefs);

	/* Window is symmetrical so only half is calculated.  Fold over 
		first half */
	for (i = (binSize/2)-1; i>=0; i--)
	{
		filterWindow[j] = (float) KB_coefs[i];
//		printf("%f\n", filterWindow[j] );
		j++;
	}
	/* Second half */
	for (i = 0; i<binSize/2; i++)
	{
		filterWindow[j] = (float) KB_coefs[i];
//		printf("%f\n", filterWindow[j] );
		j++;
	}

	/* Update instance variables */
	windowType = WINDOW_KB;
	windowCoef = alpha;

	/* free temporary data space */
	free(KB_coefs);

	return self; 
}

/*===========================================================================

	Method: setWindowSlide
	Purpose: sets the window slide for subsequent FFTs
	Parameters: 
		(int) x.  Slide in samples

===========================================================================*/
- setWindowSlide:(int)x
{
	if (windowSlide != x)
	{
		windowSlide = x;
		/* Set dirty bit if fft data exists */
		if (fftData) dirtybit = TRUE;
	}

	return self; 
}

/*===========================================================================

	Method: setBinSize
	Purpose: set bin size for subsequent FFT's
	Parameters: 
		(int) x.  Size in samples

===========================================================================*/
- setBinSize:(int)x
{

	if (x!=binSize)
	{
		binSize = x;
		/* Set dirty bit if fft data exists */
		if (fftData) dirtybit = TRUE;
	}

	return self; 
}

/*===========================================================================

	Method: setSamplingRate
	Purpose: setSamplingRate of sound Data
	Parameters: 
		(int) rate.  Sampling Rate.

	NOTE: Future versions may store sampling rate as a double.

===========================================================================*/
- setSamplingRate: (int) rate
{
	if (rate!=samplingRate)
	{
		samplingRate = rate;
		if (fftData) dirtybit = TRUE;
	}

	return self; 
}

/*===========================================================================

	Method: setSoundData
	Purpose: Copies sound data and converts to float numbers between
		-1.0 and 1.0. 
	Parameters:
		(short *) newData:  The sound Data.
		(int) size: Size in bytes.
===========================================================================*/
- setSoundData: (short *) newData dataSize: (int) size
{
int i;

	dirtybit = TRUE;

	/* Free existing sound data, if any */
	if (soundData) free(soundData);

	/* Calculate size of sound data space and malloc */
	soundData = (float *) malloc(size*sizeof(float)/2);
	soundDataSize = size;

	/* Copy data and convert to floats. */
	for (i = 0; i<size/2; i++)
		soundData[i] = (float)newData[i]/32768.0;

	return self; 
}

/*===========================================================================

	Method: setFFTName
	Purpose: Name the fft.  Used for display identification.
	Parameters:
		(char *) string: Name of FFT

===========================================================================*/
- setFFTName: (char *) string
{
	/* Free current name string */
	if (name)
		free(name);

	/* Malloc space and copy string */
	name = (char *) malloc (strlen(string)+1);
	strcpy(name, string);

	return self;
}

/*===========================================================================

	Method: FFTName
	Purpose: Returns name of FFT set by previous setFFTName method call.
	Returns: 
		(char *) name instance variable.

===========================================================================*/
- (char *) FFTName
{
	if (!name)
		return ("Untitled");
	else
		return name;
}

@end
