
#import "FFT.h"
#import "structs.h"
#import <stdio.h>
#import <mach/boolean.h>
#import <math.h>

#define SWAP(a,b) tempr = (a); (a)=(b); (b)=tempr

/*===========================================================================

	Function: four1()
	Purpose: The fft function.

	NOTE:  It is not documented in Numerical recipes in C so I'm not 
		going to document it. 

	PLEASE NOTE:  They converted this routine from FORTRAN (ARGH).  Buffers
		are indexed from 1 and NOT 0.  Remember this when you are
		preparing your windows!

===========================================================================*/

four1(data, nn, isign)
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

- init
{
	filterWindowSize = 0;
	windowType = WINDOW_NONE;
	windowCoef = 0.0;
	filterWindow = NULL;

	windowSlide = 0;
	numberOfWindows = 0;
	binSize = 0;
	samplingRate = 0;

	soundDataSize = 0;
	soundData = NULL;

	dirtybit = 0;
	fftDataSize = 0;
	fftData = NULL;

	return self;
}

- free
{
	if (soundData) free(soundData);
	if (fftData) free(fftData);
	if (filterWindow) free(filterWindow);

	return self; 
}

- doAnalysis
{
float *results, *dataWindow;
double realCoef, imagCoef;
int fftSize = 0 , soundIndex = 0, resultIndex = 0, i;
int windowCount = 0;


	if (filterWindowSize == 0) [self setWindowNone];

	numberOfWindows = soundDataSize/windowSlide;
	fftSize = (binSize/2)*numberOfWindows * sizeof(float);
	results = (float *) malloc (fftSize);

	dataWindow = (float *) malloc(sizeof(float)*2*binSize + 100);	/* NOTE: +100 is a Kludge */

	while(soundIndex<soundDataSize)
	{
		[self preparePackedWindow:dataWindow fromIndex: soundIndex];
		four1(dataWindow, binSize, 1);
		for (i = 1 ; i<binSize; i+=2)
		{
			realCoef = (double) dataWindow[i]*dataWindow[i];
			imagCoef = (double) dataWindow[i+1]*dataWindow[i+1];

			results[resultIndex++] = (float) sqrt(realCoef+imagCoef);
		}


		soundIndex+=windowSlide;
	}

	return self; 
}

- doAnalysisToFile: (char *) file;
{
FILE *fp;
float *results, *dataWindow;
double realCoef, imagCoef;
struct _FFTheader FFTHeader;
int fftSize = 0 , soundIndex = 0, resultIndex = 0, i;
int windowCount = 0;

	fp = fopen (file, "w");
	if (!fp)
	{
		return nil;
	}

	if (filterWindowSize == 0) [self setWindowNone];

	bzero(&FFTHeader, sizeof (struct _FFTheader));

	numberOfWindows = soundDataSize/windowSlide;
	fftSize = (binSize/2)*numberOfWindows * sizeof(float);
	results = (float *) malloc (fftSize);

	FFTHeader.anaMagic = ANA_MAGIC;
	FFTHeader.hanning = windowType;
	FFTHeader.slide = windowSlide;
	FFTHeader.bin_size = binSize;
	FFTHeader.num_windows = numberOfWindows;
	FFTHeader.sampling_rate = samplingRate;
	fwrite(&FFTHeader, sizeof (struct _FFTheader), 1, fp);

	dataWindow = (float *) malloc(sizeof(float)*2*binSize + 100);	/* NOTE: +100 is a Kludge */

	while(soundIndex<soundDataSize)
	{
		[self preparePackedWindow:dataWindow fromIndex: soundIndex];
		four1(dataWindow, binSize, 1);

		for (i = 1 ; i<binSize; i+=2)
		{
			realCoef = (double) dataWindow[i]*dataWindow[i];
			imagCoef = (double) dataWindow[i+1]*dataWindow[i+1];

			results[resultIndex++] = (float) sqrt(realCoef+imagCoef);
		}

//		for (i = (binSize*2)-3 ; i>binSize; i-=2)
//		{
//			realCoef = (double) dataWindow[i]*dataWindow[i];
//			imagCoef = (double) dataWindow[i+1]*dataWindow[i+1];
//
//			results[resultIndex++] = (float) sqrt(realCoef+imagCoef);
//		}
//		resultIndex++;
//		soundIndex+=windowSlide*2;

		soundIndex+=windowSlide;
	}

	fwrite(results, 1, fftSize, fp);
	fclose(fp);
	return self; 
}

- preparePackedWindow:(float *) dataWindow fromIndex: (int) soundIndex
{
int i, index1, index2;

	bzero(dataWindow, sizeof(float)*binSize);

	index1 = soundIndex;
	index2 = soundIndex+windowSlide;

	for (i = 1; i<=binSize*2; i+=2)
	{
		if (index1>soundDataSize)
			dataWindow[i] = 0.0;
		else
			dataWindow[i] = soundData[index1++]*filterWindow[i/2];

		if (index2>soundDataSize)
			dataWindow[i+1] = 0.0;
		else
//			dataWindow[i+1] = soundData[index2++]*filterWindow[i/2];
			dataWindow[i+1] = 0.0;

	}
	return self;
}

- (int)windowSlide
{
	return windowSlide; 
}

- (int)numberOfWindows
{
	return numberOfWindows; 
}

- (int)binSize
{
	return binSize;
}

- (int)samplingRate
{
	return samplingRate;
}

- (int)soundDataSize
{
	return soundDataSize; 
}

- (float *)soundData
{
	return soundData; 
}

- (int)fftDataSize
{
	return fftDataSize;
}

- (float *)fftData
{
	return fftData;
}

- setWindowNone
{
int i;

	if (filterWindow) free(filterWindow);

	filterWindow = (float *) malloc(binSize*sizeof(float));
	filterWindowSize = binSize;

	for (i = 0; i<binSize; i++)
	{
		filterWindow[i] = 1.0;
	}

	windowType = WINDOW_NONE;
	windowCoef = 0.0;

	return self; 
}

#define PI 3.14159265358979

- setWindowHanning		/* Not FINISHED */
{
int i;
float temp;

	if (filterWindow) free(filterWindow);
	filterWindow = (float *) malloc(binSize*sizeof(float));
	filterWindowSize = binSize;

	for (i = 0; i<binSize; i++)
	{
		temp = 0.5*(1-cos(2.0*PI*(float)i/(float)(binSize-1)));
		if (temp<0.0) temp = -temp;
		filterWindow[i] = temp;
	}

	windowType = WINDOW_HAN;
	windowCoef = 0.0;
	return self; 
}

extern void init_KB_coefs();

- setWindowKB: (float) alpha	/* Not FINISHED */
{
int i, j = 0;
double *KB_coefs;

	if (filterWindow) free(filterWindow);
	filterWindow = (float *) malloc(binSize*sizeof(float));
	filterWindowSize = binSize;

	KB_coefs = (double *) malloc(sizeof(double)*binSize/2);

	init_KB_coefs(binSize/2, alpha, KB_coefs);
	for (i = (binSize/2)-1; i>=0; i--)
	{
		filterWindow[j] = (float) KB_coefs[i];
//		printf("%f %f\n", (float)j, filterWindow[j]);
		j++;
	}
	for (i = 0; i<binSize/2; i++)
	{
		filterWindow[j] = (float) KB_coefs[i];
//		printf("%f %f\n", (float)j, filterWindow[j]);
		j++;
	}

	windowType = WINDOW_KB;
	windowCoef = alpha;
	return self; 
}

- setWindowSlide:(int)x
{
	if (windowSlide != x)
	{
		windowSlide = x;
		if (fftData) dirtybit = TRUE;
	}

	return self; 
}

- setBinSize:(int)x
{
	if (x!=binSize)
	{
		binSize = x;
		if (fftData) dirtybit = TRUE;
	}

	return self; 
}

- setSamplingRate: (int) rate
{
	if (rate!=samplingRate)
	{
		samplingRate = rate;
		if (fftData) dirtybit = TRUE;
	}

	return self; 
}

- setSoundData: (short *) newData dataSize: (int) size
{
int i;

	dirtybit = TRUE;

	if (soundData) free(soundData);
	soundData = (float *) malloc(size*sizeof(float));
	soundDataSize = size;

	for (i = 0; i<size/2; i++)
		soundData[i] = (float)newData[i]/32768.0;

	return self; 
}

@end


main()
{
FFT *myFFT;
FILE *fp;
char sound[20000];

	fp = fopen ("zero.snd", "r");
	fread(sound, 1, 18112, fp);
	fclose(fp);

	myFFT = [[FFT alloc] init];
	if (!myFFT)
	{
		printf("Cannot alloc FFT\n");
		exit(1);
	}

	[myFFT setWindowSlide:64];
	[myFFT setBinSize:512];
	[myFFT setSamplingRate:11025];
	[myFFT setSoundData: sound dataSize:18112];
	[myFFT setWindowHanning];
//	[myFFT setWindowNone];
//	[myFFT setWindowKB: 2.5];


	[myFFT doAnalysisToFile: "test.out"];
	exit(0);

}
