#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "structs.h"
#include "soundstruct.h"

/*===========================================================================

	FILE: fft.c
	Description:  Performs an FFT on a NeXT soundfile.  Supports:
		Mono sound files only.
		11025, 22050, and 44100 Hz sampling rates.
		Windows of 128, 256, and 512 samples.

	Author: Craig-Richard Schock.
		Updated for CPSC 550 on Sat Sep. 19, 1992.

===========================================================================*/		

/*===========================================================================

	This file contains the FFT code taken from `Numerical Recipes in C.'
	As per the publisher's instructions, it may not be used for 
	commercial activities.

===========================================================================*/

#define SWAP(a,b) tempr = (a); (a)=(b); (b)=tempr
#define PI 3.14159265358979
#define DEG_TO_RAD ((2.0*PI)/360.0)
#define RAD_TO_DEG (360.0/(2.0*PI))

float hanning[512];		/* Hanning window, maximum 512 samples */
int han = 0;			/* Hanning window flag */
int kb_window = 0;		/* Use window other than hanning but set hanning flag */
double kb_alpha;
unsigned short kb_half;
int print = 0;			/* Print out hanning/alternate window for graphing */
int sampleSkip;			/* Skip N samples due to sampling rate difference */
int windowSize;			/* Size of sampling window (and hanning window) */
int windowSlide;		/* Slide window N samples */

FILE *fp,*fpout;

extern double KB_coefs[];

#ifdef DSPFFT
#define KLUDGE 0
#endif

#ifndef DSPFFT
#define KLUDGE 1
#endif

/*===========================================================================

	Function: fft
	Purpose: This funtion is the top level fft function.  It bascially
		initializes the fft and then calls another function to 
		perform it.  If any errors are encountered, an error message
		is printed to stderr and a negative 1 (-1) is returned to
		the calling function.

	Parameters: 
		(char *) soundfile:  Null-terminated name of the sound file.
		(char *) resultfile: Null-terminated name of the fft file (output).
		(struct _FFTheader *) fftStruct:  pointer to the output file
				header information. consult file "structs.h" for
				definition.

===========================================================================*/

fft(fftStruct)
struct _FFTheader *fftStruct;
{
SNDSoundStruct header;

	/* Read in sound file header. */
	fread(&header,sizeof(header),1,fp);

	/* Check file's magic number.  If != to SND_MAGIC, return with error */
	if (header.magic!=SND_MAGIC)
	{
		fprintf(stderr,"Input file is not a sound file.\n");
		return(-1);
	}

	/* Set up sample skip based on sampling rate. Return error if necessary */
	switch(header.samplingRate)
	{
		case (int)SND_RATE_CODEC: /* Codec not supported in this version */
			fprintf(stderr,"Cannot convert soundfile from CODEC format\n");
			return(-1);
			break;

		case SND_RATE_FFT:	  /* Format is just right.  Use all samples */
			printf("Sample skip = 1\n");
			sampleSkip = 1;
			break;

		case (int)SND_RATE_LOW:   /* 22050 Hz format.  2x too high. Use every 2nd sample */
			printf("Sample skip = 2\n");
			sampleSkip = 2;
			break;

		case (int)SND_RATE_HIGH:  /* Whoa, slow them horses down.  Sample rate 4x too high. */
			printf("Sample skip = 4\n");
			sampleSkip = 4;
			break;

		default:	     /* Unknown sampling rate.  Unsupported */
			fprintf(stderr,"Unknown sampling rate. Not supported\n");
			return(-1);
			break;
	}

	/* Check channel count.  We can only deal with mono sound files (right now) */
	if (header.channelCount!=1)
	{
		fprintf(stderr,"Do not support stereo sound files.  Convert to mono.\n");
		return(-1);
	}

	fftStruct->num_windows = (header.dataSize/(sampleSkip*windowSlide*2));

	/* Write the header in.  If header cannot be written, return (-1) */
	if ( write_header(fftStruct)== (-1) )
	{
		fprintf(stderr,"Could not write FFT header\n");
		return(-1);
	}

	/* Actually do the fft!  finally! */
	do_fft(&header, fftStruct);

	/* All went OK.... well.. it finished... without crashing! */
	return(0);
}

/*===========================================================================

	Function: do_fft
	Purpose: Feeds successive windows to the four1 or dspfft function.
		 Store results onto disk.

	Information is needed from both the sound file header and the
	fft file header.  Pointers to both are passed as parameters.

	NOTE: Slices and dices but does not Julien.  See function "cuisinart"
		for that ability.

===========================================================================*/

do_fft(SNDheader, FFTheader)
SNDSoundStruct *SNDheader;
struct _FFTheader *FFTheader;
{
int totalSamples, sampleSlide, index = 0;
float *window;
float output[256];
short int *buffer;


	/* To skip a sample, we must skip 2 bytes. */
//	sampleSlide = windowSlide*2*sampleSkip;
	sampleSlide = windowSlide*sampleSkip;

	/* If user requested a hanning window, construct it */
	if (kb_window)
		make_kbWindow();
	else
	if (han)
		make_hanning();

	/* Each sample is 16 bits.  From the sound header file, calculate
	   the number of samples in total and reserve a buffer.*/
	totalSamples = SNDheader->dataSize/2;
	buffer = (short int *) malloc(SNDheader->dataSize);

	/* Seek to where the samples begin.  Read in the whole lot of 'em. 
	   Yup! That's right.  I'm a memory pig and PROUD of it too!       */
	fseek(fp, SNDheader->dataLocation, SEEK_SET);
	fread(buffer, 1, SNDheader->dataSize, fp);

	/* Close input file.  All information is now in memory */
	fclose(fp);

	/* Allocation space for the window buffer.  NOTE: Because the window
	   is a buffer of Imaginary numbers, allocate 2 x windowSize to hold
	   both the real and imaginary portions of the sample */

	window = (float *) malloc(windowSize*2*sizeof(float));

	/* Keep going until we've done all windows */
	while(index<totalSamples)
	{
		/* Make up a window from sample data. */
		prepare_window(buffer, index, window, totalSamples);

		/* On suns, use four1.  On NeXT use dspfft. */
		four1(window, windowSize, 1);

		/* Put the results onto disk.  Hope the sysops don't mind. */
		write_results(window);

		index+=sampleSlide;			/* Slide window along */
//		printf("%d\n", index);
	}

	/* Free all the samples */
	free(buffer);
}

/*===========================================================================

	Function: prepare_window()
	Purpose: Prepare a window to be FFTed.  Normalize if necessary.
		 Window must be put into "*window". 

	Data Format: (Also see NOTE below)
		FFT's work on imaginary numbers.  Therefore, the real portion
		of the sample is put in window[i] while the imaginary portion
		is put in window[i+1].  Therefore, to index into the window
		at postion 'x', use the formula: 
			real 		= window[x*2];
			imaginary 	= window[(x*2)+1];

	Parameters: 
		(short int *) buffer: Pointer to sample space. (words)
		(int) index: Index into sample space.
		(float *) window: Pointer to window buffer.
		(int) han_window: Is hanning window used?
		(int) maxSamples: if we go past the end of the buffer, pad with 0's.

	NOTE: Numerical recipes in C REALLY goofed on this one.  Their 
		"four1" indexes buffers from 1 NOT 0.  ARGH!  Fortran
		rears its ugly head again!

===========================================================================*/

prepare_window(buffer, index, window, maxSamples)
short int *buffer;
int index, maxSamples;
float *window;
{
int i;
float temp;

	for (i = 0;i<windowSize;i++)
	{
		if ((index+(i*2))>maxSamples)
		{
			window[i*2+KLUDGE] = window[i*2+KLUDGE+1] = 0.0;	/* Pad with 0.0 */
		}
		else
		{
			temp = (float) (buffer[index+(i*sampleSkip)])/(32768.0);
//			printf("%f ", temp);
			if (han) temp*=hanning[i];
//			printf("%f\n", temp);
			window[i*2+KLUDGE] = temp;
			window[i*2+1+KLUDGE] = 0.0;
		}
//		printf("%d: %f\n", i, window[i*2+KLUDGE]);

	}
}

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

/*===========================================================================

	Function: write_header
	Purpose: To write the header for the FFT file.

===========================================================================*/

write_header(fftStruct)
struct _FFTheader *fftStruct;
{

	fftStruct->anaMagic = ANA_MAGIC;
	fwrite(fftStruct, 1, sizeof(struct _FFTheader), fpout);
	return(0);
}

/*===========================================================================

	Function: write_results
	Purpose: To write the results of the fft (for this window) to disk.

	NOTE: We are calculating the amplitude.  We are not writing the
		fft parameters directly.  By using this format we are 
		losing all phase information.

===========================================================================*/

write_results(window)
float *window;
{
int i, j;
struct _data512 temp;

	/* Zero the bits in the struct */
	bzero(&temp, sizeof (struct _data512));

	/* Calculate the hypotenuse (amplitude ) */
	j = 0;
	for (i = 0;i < windowSize; i+=2)
	{
		temp.data[j++] = (float) sqrt( ((double) (window[i+1]*window[i+1])) +
				               ((double) (window[i+2]*window[i+2])));
//		printf("%d: %f  %f  %f\n", j, temp.data[j-1], window[i+1], window[i+2]);
	}

	/* Store the propper sized data */
	switch(windowSize)
	{
		case 128: fwrite(&temp,sizeof(struct _data128),1,fpout);
			 break;

		case 256: fwrite(&temp,sizeof(struct _data256),1,fpout);
			 break;

		case 512: fwrite(&temp,sizeof(struct _data512),1,fpout);
			 break;
	}

}

/*===========================================================================

	Funtion: make_hanning
	Purpose: To make a hanning window based on our windowSize.

===========================================================================*/

make_hanning()
{
register int i;
float temp;

	han = 1;
	for (i = 0;i<windowSize;i++)
	{
		temp = 0.5*(1-cos(2.0*PI*(float)i/(float)(windowSize-1)));
		if (temp<0.0) temp = -temp;
		hanning[i] = temp;
		if (print)
			printf("%f %f\n", (float)i, temp);
	}
}

/*===========================================================================

	Funtion: make_kbWindow
	Purpose: To make a hanning window based on our windowSize.

===========================================================================*/

make_kbWindow()
{
int i, j = 0;

        init_KB_coefs(kb_half, kb_alpha);
        for (i = kb_half-1; i>=0; i--)
	{
		hanning[j] = KB_coefs[i];
		if (print)
			printf("%f %f\n", (float)j, hanning[j]);
		j++;
	}
        for (i = 0; i<kb_half; i++)
	{
		hanning[j] = KB_coefs[i];
		if (print)
			printf("%f %f\n", (float)j, hanning[j]);
		j++;
	}
}

usage(string)
char *string;
{
	printf("Usage: %s -help\n", string);
	printf("Usage: %s -bin [128, 256 or 512] -f soundfile -o resultfile [-slide #Samples] [-han] [-p] [-k alpha] \n", string);
	exit(0);
}

main(argc, argv)
int argc;
char *argv[];
{
struct _FFTheader fftHeader;
int i = 1;


	/* If only 1 argument, print out usage string */
	if (argc == 1)	usage(argv[0]);

	/* Initialize the header for the FFT file */
	bzero(&fftHeader, sizeof(struct _FFTheader));

	/* Initialize parameters */
	windowSlide = (-1);
	windowSize = (-1);
	han = (-1);
	fp = fpout = NULL;

	while(i<argc)
	{
		if (argv[i][0] == '-')
		{
			switch(argv[i][1])
			{
				case 'b': /* Set bin size */
					 windowSize = atoi(argv[i+1]);
					 i+=2;
					 if ( (windowSize!=128) && (windowSize!=256) && (windowSize!=512))
					 {
						printf("Window size must be either 128, 256, or 512 samples\n");
						exit(0);
					 }
					 else
						 printf("Window size set to: %d\n", windowSize);
					 break;

				case 's': /* Set window slide */
					 printf("Window slide set to: %s\n", argv[i+1]);
					 windowSlide = atoi(argv[i+1]);
					 i+=2;
					 break;

				case 'h': if (argv[i][2] == 'e')
					  {
						printf("Help.\n");
						exit(0);
					  }
					  else
					  { 
					 	/* turn on hanning window */
					 	printf("Hanning Window ON.\n");
						han = 1;
					 	i++;
					 	break;
					  }

				case 'f': /* define input sound file */
					 fp = fopen(argv[i+1],"r");
					 if (fp == NULL) 
					 {
						fprintf(stderr, "Cannot open sound file named \"%s\"\n", argv[i+1]);
						exit(0);
					 }
					 else
						 printf("Input file: \"%s\"\n", argv[i+1]);
					 i+=2;
					 break;

				case 'o': /* define output file */
					 fpout = fopen(argv[i+1], "w");
					 if (fpout == NULL)
					 {
						fprintf(stderr,"Cannot open file named \"%s\" for writing\n", argv[i+1]);
						exit(0);
					 }
					 else
						printf("Output file: \"%s\"\n", argv[i+1]);
					 i+=2;
					break;

				case 'p': /* Print out multiplier window */
					print = 1;
					i++;
					break;

				case 'k': /* Use other window */
					printf("Using alternate window\n");
					han = 1;
					kb_window = 1;
					kb_alpha = (double) atof(argv[i+1]);
					printf("Using KB window. Alpha = %f\n", kb_alpha);
					i+=2;
					break;

				default: fprintf(stderr,"Unknown flag \"%s\"\n", argv[i]);
					 exit(0);
			}
		}
	}

	if (fp == NULL)
	{
		printf("You must define an input file\n");
		exit(0);
	}

	if (fpout == NULL)
	{
		printf("You must define an output file\n");
		exit(0);
	}

	if (windowSize == (-1))
	{
		printf("You must define a window size.  Either 128, 256, or 512 samples\n");
		exit(0);
	}

	if (han == (-1))
	{
		printf("Hanning window OFF\n");
		han = 0;
	}
	if (windowSlide == (-1))
	{
		printf("Window Slide defaulting to Window size\n");
		windowSlide = windowSize;
	}

	if (kb_window)
		kb_half = windowSize/2;

	fftHeader.hanning = han;
	fftHeader.slide = windowSlide;
	fftHeader.bin_size = windowSize;
	fftHeader.sampling_rate = 11025;

	fft(&fftHeader);

	exit(0);
}

