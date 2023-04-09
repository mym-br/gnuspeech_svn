/*******************************************************************************
 *
 *  Copyright 1991-2009 David R. Hill, Leonard Manzara, Craig Schock
 *
 *  Contributors: David Hill
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *******************************************************************************
 *
 *  tube.c
 *  Synthesizer
 *
 *  Created by David Hill in 2006.
 *
 *  Version: 0.7.3
 *
 ******************************************************************************/


/*  REVISION INFORMATION  *****************************************************
$Author: len $
$Date: 1995/04/17 19:51:21 $
$Revision: 1.9 $
$Source: /cvsroot/softwareTRM/tube.c,v $
$State: Exp $


$Log: tube.c,v $
 * Revision 1.10 2009-04-19 15:14
 * Initial 0.7 release -- added pthread and buffers needed to interface with Objective-C
 * components created to implement "Synthesizer" for the Macintosh under OS X
 * Note that the frication volume final output increases when glottal volume decreases.
 * This needs to be fixed!
 *
 * Revision 1.9 2006/04/01 18:11 david
 * Remove all things not required for running Synthesizer & split off structures
 *
 * Revision 1.8  1995/04/17  19:51:21  len
 * Temporary fix to frication balance.
 *
 * Revision 1.7  1995/03/21  04:52:37  len
 * Now compiles FAT.  Also adjusted mono and stereo output volume to match
 * approximately the output volume of the DSP.
 *
 * Revision 1.6  1995/03/04  05:55:57  len
 * Changed controlRate parameter to a float.
 *
 * Revision 1.5  1995/03/02  04:33:04  len
 * Added amplitude scaling to input of vocal tract and throat, to keep the
 * software TRM in line with the DSP version.
 *
 * Revision 1.4  1994/11/24  05:24:12  len
 * Added Hi/Low output sample rate switch.
 *
 * Revision 1.3  1994/10/20  21:20:19  len
 * Changed nose and mouth aperture filter coefficients, so now specified as
 * Hz values (which scale appropriately as the tube length changes), rather
 * than arbitrary coefficient values (which don't scale).
 *
 * Revision 1.2  1994/08/05  03:12:52  len
 * Resectioned tube so that it more closely conforms the the DRM proportions.
 * Also changed frication injection so now allowed from S3 to S10.
 *
 * Revision 1.1.1.1  1994/07/07  03:48:52  len
 * Initial archived version.
 *

******************************************************************************/


/******************************************************************************
*
*     Program:       tube
*
*     Description:   Software (non-real-time) implementation of the Tube
*                    Resonance Model for speech production.
*
*     Author:        Leonard Manzara
*
*     Date:          July 5th, 1994
*
******************************************************************************/

#include "tube.h"

/*  HEADER FILES  ************************************************************/
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/param.h>
#include <math.h>
#include <string.h>
#include <pthread.h>
#ifdef GNUSTEP
# include <time.h>
# include "jack_data.h"
#endif

//#define DEBUG_TUBE 1

#define CONTROL_RATE          100.0

/*  GLOTTAL SOURCE OSCILLATOR TABLE VARIABLES  */
//#define TABLE_LENGTH              512
#define TABLE_MODULUS             (TABLE_LENGTH-1)

/*  COMPILE WITH OVERSAMPLING OR PLAIN OSCILLATOR  */
#define OVERSAMPLING_OSCILLATOR   1

/*  1 MEANS COMPILE SO THAT INTERPOLATION NOT DONE FOR
    SOME CONTROL RATE PARAMETERS  */
#define MATCH_DSP                 0

/*  OROPHARYNX REGIONS  */
#define R1                        0      /*  S1  */
#define R2                        1      /*  S2  */
#define R3                        2      /*  S3  */
#define R4                        3      /*  S4 & S5  */
#define R5                        4      /*  S6 & S7  */
#define R6                        5      /*  S8  */
#define R7                        6      /*  S9  */
#define R8                        7      /*  S10  */
//#define TOTAL_REGIONS             8  (moved to tube.h)

/*  OROPHARYNX SCATTERING JUNCTION COEFFICIENTS (BETWEEN EACH REGION)  */
#define C1                        R1     /*  R1-R2 (S1-S2)  */
#define C2                        R2     /*  R2-R3 (S2-S3)  */
#define C3                        R3     /*  R3-R4 (S3-S4)  */
#define C4                        R4     /*  R4-R5 (S5-S6)  */
#define C5                        R5     /*  R5-R6 (S7-S8)  */
#define C6                        R6     /*  R6-R7 (S8-S9)  */
#define C7                        R7     /*  R7-R8 (S9-S10)  */
#define C8                        R8     /*  R8-AIR (S10-AIR)  */
#define TOTAL_COEFFICIENTS        TOTAL_REGIONS

/*  OROPHARYNX SECTIONS  */
#define S1                        0      /*  R1  */
#define S2                        1      /*  R2  */
#define S3                        2      /*  R3  */
#define S4                        3      /*  R4  */
#define S5                        4      /*  R4  */
#define S6                        5      /*  R5  */
#define S7                        6      /*  R5  */
#define S8                        7      /*  R6  */
#define S9                        8      /*  R7  */
#define S10                       9      /*  R8  */
//#define TOTAL_SECTIONS            10  (moved to tube.h)

/*  NASAL TRACT SECTIONS  */
#define N1                        0
#define VELUM                     N1
#define N2                        1
#define N3                        2
#define N4                        3
#define N5                        4
#define N6                        5
#define TOTAL_NASAL_SECTIONS      6

/*  NASAL TRACT COEFFICIENTS  */
#define NC1                       N1     /*  N1-N2  */
#define NC2                       N2     /*  N2-N3  */
#define NC3                       N3     /*  N3-N4  */
#define NC4                       N4     /*  N4-N5  */
#define NC5                       N5     /*  N5-N6  */
#define NC6                       N6     /*  N6-AIR  */
#define TOTAL_NASAL_COEFFICIENTS  TOTAL_NASAL_SECTIONS

/*  THREE-WAY JUNCTION ALPHA COEFFICIENTS  */
#define LEFT                      0
#define RIGHT                     1
#define UPPER                     2
#define TOTAL_ALPHA_COEFFICIENTS  3

/*  FRICATION INJECTION COEFFICIENTS  */
#define FC1                       0      /*  S3  */
#define FC2                       1      /*  S4  */
#define FC3                       2      /*  S5  */
#define FC4                       3      /*  S6  */
#define FC5                       4      /*  S7  */
#define FC6                       5      /*  S8  */
#define FC7                       6      /*  S9  */
#define FC8                       7      /*  S10  */
#define TOTAL_FRIC_COEFFICIENTS   8

/*  GLOTTAL SOURCE OSCILLATOR TABLE VARIABLES  */
//#define TABLE_LENGTH              512
//#define TABLE_MODULUS             (TABLE_LENGTH-1)

/*  WAVEFORM TYPES  */
#define PULSE                     0
#define SINE                      1

/*  OVERSAMPLING FIR FILTER CHARACTERISTICS  */
#define FIR_BETA                  .2
#define FIR_GAMMA                 .1
#define FIR_CUTOFF                .00000001

/*  PITCH VARIABLES  */
#define PITCH_BASE                220.0
#define PITCH_OFFSET              3           /*  MIDDLE C = 0  */
#define LOG_FACTOR                3.32193

/*  RANGE OF ALL VOLUME CONTROLS  */
#define VOL_MAX                   60

/*  SCALING CONSTANT FOR INPUT TO VOCAL TRACT & THROAT (MATCHES DSP)  */
//#define VT_SCALE                  0.03125     /*  2^(-5)  */
// this is a temporary fix only, to try to match dsp synthesizer
#define VT_SCALE                  0.125     /*  2^(-3)  */

/*  FINAL OUTPUT SCALING, SO THAT .SND FILES APPROX. MATCH DSP OUTPUT  */
#define OUTPUT_SCALE              0.25

/*  CONSTANTS FOR THE FIR FILTER  */
#define LIMIT                     200
#define BETA_OUT_OF_RANGE         1
#define GAMMA_OUT_OF_RANGE        2
#define GAMMA_TOO_SMALL           3

/*  CONSTANTS FOR NOISE GENERATOR  */
#define FACTOR                    377.0
#define INITIAL_SEED              0.7892347

/*  MAXIMUM SAMPLE VALUE  */
#define RANGE_MAX                 32767.0

/*  FUNCTION RETURN CONSTANTS  */
#define ERROR                     (-1)
#define SUCCESS                   0

/*  BI-DIRECTIONAL TRANSMISSION LINE POINTERS  */
#define TOP                       0
#define BOTTOM                    1

/*  SAMPLE RATE CONVERSION CONSTANTS  */
#define ZERO_CROSSINGS            13                 /*  SRC CUTOFF FRQ      */
#define LP_CUTOFF                 (11.0/13.0)        /*  (0.846 OF NYQUIST)  */

#define N_BITS                    16
#define L_BITS                    8
#define L_RANGE                   256                  /*  must be 2^L_BITS  */
#define M_BITS                    8
#define M_RANGE                   256                  /*  must be 2^M_BITS  */
#define FRACTION_BITS             (L_BITS + M_BITS)
#define FRACTION_RANGE            65536         /*  must be 2^FRACTION_BITS  */
#define FILTER_LENGTH             (ZERO_CROSSINGS * L_RANGE)
#define FILTER_LIMIT              (FILTER_LENGTH - 1)

#define N_MASK                    0xFFFF0000
#define L_MASK                    0x0000FF00
#define M_MASK                    0x000000FF
#define FRACTION_MASK             0x0000FFFF

#define nValue(x)                 (((x) & N_MASK) >> FRACTION_BITS)
#define lValue(x)                 (((x) & L_MASK) >> M_BITS)
#define mValue(x)                 ((x) & M_MASK)
#define fractionValue(x)          ((x) & FRACTION_MASK)

#define BETA                      5.658        /*  kaiser window parameters  */
#define IzeroEPSILON              1E-21

#define OUTPUT_SRATE_LOW          22050.0      /* not used apparently */
#define OUTPUT_SRATE_HIGH         44100.0      /* not used apparently */
#define BUFFER_SIZE               1024                 /*  ring buffer size  */

/*  OUTPUT FILE FORMAT CONSTANTS  */
#define AU_FILE_FORMAT            0
#define AIFF_FILE_FORMAT          1
#define WAVE_FILE_FORMAT          2

/*  SIZE IN BITS PER OUTPUT SAMPLE  */
#define BITS_PER_SAMPLE           16

/*  BOOLEAN CONSTANTS  */
#define FALSE                     0
#define TRUE                      1

#define CIRC_BUFF2_SIZE			8192
#define EMPTY					-1
#define FULL					1
#define OK						0



/*  VARIABLES FOR INTERPOLATION  */
typedef struct {
	float glotPitch;
	float glotVol;
	float aspVol;
	float fricVol;
	float fricPos;
	float fricCF;
	float fricBW;
	float velum;
	float radius[TOTAL_REGIONS];
	float noseRadius[TOTAL_NASAL_SECTIONS];
} interpolated_parameters_t;



extern float PI, PI2;



/*  GLOBAL VARIABLES *********************************************************/

/*  INPUT VARIABLES  */
static float  outputRate = 44100.0;        /*  output sample rate (22.05, 44.1 KHz)  */
static float  controlRate = CONTROL_RATE;  /*  1.0-1000.0 input tables/second (Hz)  */

//static float  volume = 60.0;               /*  master volume (0 - 60 dB)  */
//static int    channels = 1;                /*  # of sound output channels (1, 2)  */
//static float  balance = 0.0;               /*  stereo balance (-1 to +1)  */

static int    waveform = 0;                /*  GS waveform type (0=PULSE, 1=SINE)  */

static float  tp = 35.0;                   /*  % glottal pulse rise time  */
static float  tnMin = 16.0;                /*  % glottal pulse fall time minimum  */
static float  tnMax = 40.0;                /*  % glottal pulse fall time maximum  */
static float  breathiness = 2.5;           /*  % glottal source breathiness  */

static float  length = 17.0;               /*  nominal tube length (10 - 20 cm)  */
static float  temperature = 32.0;          /*  tube temperature (25 - 40 C)  */
static float  lossFactor;                  /*  junction loss factor in (0 - 5 %)  */

static float  apScale = 3.05;              /*  aperture scl. radius (3.05 - 12 cm)  */
static float  mouthCoef = 4000.0;          /*  mouth aperture coefficient  */
static float  noseCoef = 5000.0;           /*  nose aperture coefficient  */

static float  throatCutoff = 1500.0;       /*  throat lp cutoff (50 - nyquist Hz)  */
static float  throatVol = 6.0;             /*  throat volume (0 - 48 dB) */

static int    modulation = 1;              /*  pulse mod. of noise (0=OFF, 1=ON)  */
static float  mixOffset = 48.0;            /*  noise crossmix offset (30 - 60 dB)  */

/*  DERIVED VALUES  */
static int    controlPeriod;
static int    sampleRate;
static float  actualTubeLength;            /*  actual length in cm  */

static double dampingFactor;               /*  calculated damping factor  */
static double crossmixFactor;              /*  calculated crossmix factor  */

static int    tableDiv1;
static float  wavetable[TABLE_LENGTH];
static int    tableDiv2;
static double tnLength;
static double tnDelta;
static double basicIncrement;

static double breathinessFactor;

/*  POSITION IN THE WAVETABLE  */
static double currentPosition;

/*  MEMORY FOR TUBE AND TUBE COEFFICIENTS  */
static double oropharynx[TOTAL_SECTIONS][2][2];
static double oropharynx_coeff[TOTAL_COEFFICIENTS];

static double nasal[TOTAL_NASAL_SECTIONS][2][2];
static double nasal_coeff[TOTAL_NASAL_COEFFICIENTS];

static double alpha[TOTAL_ALPHA_COEFFICIENTS];
static int current_ptr = 1;
static int prev_ptr = 0;

/* CIRCULAR BUFFER FOR RECEIVING SAMPLES */
static float circBuff[CIRC_BUFF_SIZE];
static float *circBuffStart = &circBuff[0];
static float *circBuffInPtr = &circBuff[0];
static float *circBuffOutPtr = &circBuff[1];
static float *circBuffEnd = &circBuff[CIRC_BUFF_SIZE - 1];
//static int circBuffFlag = EMPTY;

#ifndef GNUSTEP
/* CIRCULAR BUFFER FOR RECEIVING OUTPUT SAMPLES */
static float circBuff2[CIRC_BUFF2_SIZE];
static float *circBuff2Start;
static float *circBuff2InPtr;
static float *circBuff2OutPtr;
static float *circBuff2End;
static int circBuff2Flag;
static int circBuff2Count;
#endif

/*  REFLECTION AND RADIATION FILTER MEMORY  */
static double a10, b11, a20, a21, b21;

/*  NASAL REFLECTION AND RADIATION FILTER MEMORY  */
static double na10, nb11, na20, na21, nb21;

/*  THROAT LOWPASS FILTER MEMORY, GAIN  */
static double tb1, ta0, throatGain;

/*  FRICATION BANDPASS FILTER MEMORY  */
static double bpAlpha, bpBeta, bpGamma;

/*  TEMPORARY SAMPLE STORAGE VALUES  */
static double maximumSampleValue = 0.0;
static long int numberSamples = 0;

/*  MEMORY FOR FRICATION TAPS  */
static double fricationTap[TOTAL_FRIC_COEFFICIENTS];

/*  VARIABLES FOR FIR LOWPASS FILTER  */
static double *FIRData, *FIRCoef;
static int FIRPtr, numberTaps;

/*  VARIABLES FOR SAMPLE RATE CONVERSION  */

static double sampleRateRatio;
static double h[FILTER_LENGTH], deltaH[FILTER_LENGTH], buffer[BUFFER_SIZE];
static int fillPtr, emptyPtr = 0, padSize, fillSize;
static unsigned int timeRegisterIncrement, filterIncrement, phaseIncrement;
static unsigned int timeRegister = 0;

static double originalTime, outputTime /*, signal1, signal2*/; // Keep track of where we are in resampling
static double originalPeriod, outputPeriod; // The two sample periods
static int sampleCount;

static interpolated_parameters_t originalDefaults =
		{ GLOT_PITCH_DEF, GLOT_VOL_DEF, 0.0, 0.0, 8.0, 2000.0, 250.0, 0.0,
		  { 0.8, 1.67, 1.905, 1.985, 0.81, 0.495, 0.73, 1.485 }, // ee
		  { 1.35, 1.35, 1.7, 1.7, 1.3, 0.9 }
		};
static interpolated_parameters_t current =
		{ GLOT_PITCH_DEF, GLOT_VOL_DEF, 0.0, 0.0, 8.0, 2000.0, 250.0, 0.0,
		  { 0.8, 1.67, 1.905, 1.985, 0.81, 0.495, 0.73, 1.485 }, // ee
		  { 1.35, 1.35, 1.7, 1.7, 1.3, 0.9 }
		};;
static interpolated_parameters_t inputParameters =
		{ GLOT_PITCH_DEF, GLOT_VOL_DEF, 0.0, 0.0, 8.0, 2000.0, 250.0, 0.0,
		  { 0.8, 1.67, 1.905, 1.985, 0.81, 0.495, 0.73, 1.485 }, // ee
		  { 1.35, 1.35, 1.7, 1.7, 1.3, 0.9 }
		};;
static interpolated_parameters_t parametersDelta;

//static void *currentPointer = &current;

static pthread_mutex_t circBuffMutex = PTHREAD_MUTEX_INITIALIZER;
//static pthread_cond_t circBuffCond = PTHREAD_COND_INITIALIZER;

#ifndef GNUSTEP
static pthread_mutex_t circBuff2Mutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t circBuff2Cond = PTHREAD_COND_INITIALIZER;
#endif

static pthread_t tubeThread;
#define TUBE_THREAD_STATUS_STOPPED 0
#define TUBE_THREAD_STATUS_STARTED 1
static int tubeThreadStatus = TUBE_THREAD_STATUS_STOPPED;
#define TUBE_THREAD_FLAG_EXIT 0    /* the thread must end (set by the main thread) */
#define TUBE_THREAD_FLAG_RUNNING 1 /* the thread is running (set by the tube thread) */
static int tubeThreadFlag = TUBE_THREAD_FLAG_EXIT;
static pthread_mutex_t tubeThreadFlagMutex = PTHREAD_MUTEX_INITIALIZER;

// Flag to signal pitch period
static int pitchFlag = 0; // 0 unless pitch period just started



/*  GLOBAL FUNCTIONS (LOCAL TO THIS FILE)  ***********************************/

//static void resample(double value);

static void initCircBuff();
static void putCircBuff(float circBuffValue);

#ifndef GNUSTEP
static void initCircBuff2();
static int putCircBuff2(float circBuffValue);
static float getCircBuff2();
static void fillAudioBuff(float * buf, int count);
#endif

//static void setupInputTables(double glotPitch, double glotVol, double aspVol, double fricVol, double fricPos, double fricCF,
//						double fricBW, double *radius, double velum);

//void printInfo(void);
//int parseInputFile(char *inputFile);

static void initializeWavetable(void);
static double speedOfSound(double temperature);
static void updateWavetable(double amplitude);
static void initializeFIR(double beta, double gamma, double cutoff);
static double noise(void);
static double noiseFilter(double input);
static void initializeMouthCoefficients(double coeff);
static double reflectionFilter(double input);
static double radiationFilter(double input);
static void initializeNasalFilterCoefficients(double coeff);
static double nasalReflectionFilter(double input);
static double nasalRadiationFilter(double input);
static void initializeNasalCavity(void);
static void initializeThroat(void);
static void calculateTubeCoefficients(void);
static void setFricationTaps(void);
static void calculateBandpassCoefficients(void);
static double mod0(double value);
static void incrementTablePosition(double frequency);
static double oscillator(double frequency);
static double vocalTract(double input, double frication);
static double throat(double input);
static double bandpassFilter(double input);
static int maximallyFlat(double beta, double gamma, int *np, double *coefficient);
static void trim(double cutoff, int *numberCoefficients, double *coefficient);
static void rationalApproximation(double number, int *order, int *numerator, int *denominator);
static double FIRFilter(double input, int needOutput);
static int increment(int pointer, int modulus);
static int decrement(int pointer, int modulus);
static void initializeConversion(void);
static void initializeFilter(void);
static void initializeBuffer(void);
static void dataFill(double data);
static void dataEmpty(void);
//static void flushBuffer(void);
static void srIncrement(int *pointer, int modulus);
static void srDecrement(int *pointer, int modulus);

static void* synthesize();

static void setTubeThreadFlag(int value);
static int getTubeThreadFlag();
static int stopTubeThread();
static void setControlPeriodParameters();
static void sampleRateInterpolation();



void setTubeThreadFlag(int value)
{
	int lockError = pthread_mutex_lock(&tubeThreadFlagMutex);
	assert(!lockError);

	tubeThreadFlag = value;

	pthread_mutex_unlock(&tubeThreadFlagMutex);
}

int getTubeThreadFlag()
{
	int lockError = pthread_mutex_lock(&tubeThreadFlagMutex);
	assert(!lockError);

	int flagValue = tubeThreadFlag;

	pthread_mutex_unlock(&tubeThreadFlagMutex);

	return flagValue;
}

// Return value: 0 - success / != 0 - error number
int stopTubeThread()
{
	setTubeThreadFlag(TUBE_THREAD_FLAG_EXIT);

	return pthread_join(tubeThread, NULL);
}

/******************************************************************************
*
*	function:	speedOfSound
*
*	purpose:	Returns the speed of sound according to the value of
*                       the temperature (in Celsius degrees).
*
*       arguments:      temperature
*
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

double speedOfSound(double temperature)
{
	double computedSpeed = (331.4 + (0.6 * (double) temperature));
	printf("In tube.c:(sp-of-snd) temperature passed is %f computed value s-o-snd %f\n", temperature, computedSpeed);
    return computedSpeed;
}



/******************************************************************************
*
*	function:	initializeSynthesizer
*
*	purpose:	Initializes all variables so that the synthesis can
*                       be run.
*
*       arguments:      none
*
*	internal
*	functions:	speedOfSound, amplitude, initializeWavetable,
*                       initializeFIR, initializeNasalFilterCoefficients,
*                       initializeNasalCavity, initializeThroat,
*                       initializeConversion
*
*	library
*	functions:	rint, fprintf, tmpfile, rewind
*
******************************************************************************/

int tube_initializeSynthesizer()
{
	int initResult;
	double nyquist;
	printf("tube.c:initializeSynthesizer(): Initialising synthesiser\n");

	if (tubeThreadStatus == TUBE_THREAD_STATUS_STARTED) {
		tube_stopSynthesizer();
		if (tubeThreadStatus == TUBE_THREAD_STATUS_STARTED) {
			return ERROR; // could not stop the thread
		}
	}

	initCircBuff();
#ifdef GNUSTEP
	outputRate = jackData.sampleRate;
#else
	initCircBuff2();
	circBuff2Count = 0;
#endif
	originalTime = 0;
	outputTime = 0;
	sampleCount = 0;
	maximumSampleValue = 0.0;
	numberSamples = 0;

	/*  CALCULATE THE SAMPLE RATE, BASED ON NOMINAL
	 TUBE LENGTH AND SPEED OF SOUND  */
	if (length > 0.0) {
		double c = speedOfSound(temperature);
		controlPeriod = rint((c * TOTAL_SECTIONS * 100.0) / (length * controlRate));
		printf("tube.c:initializeSynthesizer(): ControlPeriod is %d \n", controlPeriod); //rint((c * TOTAL_SECTIONS * 100.0) /(length * controlRate))); //*((double *) getControlPeriod()));
		sampleRate = controlRate * controlPeriod; // ****
		originalPeriod = 1 / (double) sampleRate; // ****

		printf("tube.c:initializeSynthesizer(): SampleRate is %f control period is %d control rate is %f \n", controlRate
				* controlPeriod, controlPeriod, controlRate); //sampleRate);
		actualTubeLength = (c * TOTAL_SECTIONS * 100.0) / sampleRate;
		printf("tube.c:initializeSynthesizer(): Actual tube length is %f originalPeriod is %f sampleRate is %d\n", actualTubeLength,
				originalPeriod, sampleRate);
		nyquist = (double) sampleRate / 2.0;
	} else {
		fprintf(stderr, "tube.c:initializeSynthesizer(): Illegal tube length.\n");
		return ERROR;
	}

	/*  CALCULATE THE BREATHINESS FACTOR  */
	breathinessFactor = breathiness / 100.0;

	/*  CALCULATE CROSSMIX FACTOR  */
	crossmixFactor = 1.0 / amplitude(mixOffset);

	/*  CALCULATE THE DAMPING FACTOR  */
	dampingFactor = (1.0 - (lossFactor / 100.0));
	printf("tube.c:initializeSynthesizer(): dampingFactor is %f, lossFactor is %f\n", dampingFactor, lossFactor);

	/*  INITIALIZE THE WAVE TABLE  */
	initializeWavetable();

	/*  INITIALIZE THE FIR FILTER  */
	initializeFIR(FIR_BETA, FIR_GAMMA, FIR_CUTOFF);

	/*  INITIALIZE REFLECTION AND RADIATION FILTER COEFFICIENTS FOR MOUTH  */
	initializeMouthCoefficients((nyquist - mouthCoef) / nyquist);

	/*  INITIALIZE REFLECTION AND RADIATION FILTER COEFFICIENTS FOR NOSE  */
	initializeNasalFilterCoefficients((nyquist - noseCoef) / nyquist);

	/*  INITIALIZE NASAL CAVITY FIXED SCATTERING COEFFICIENTS  */
	//initializeNasalCavity();

	/*  INITIALIZE THE THROAT LOWPASS FILTER  */
	initializeThroat();

	/*  INITIALIZE THE SAMPLE RATE CONVERSION ROUTINES  */
	initializeConversion();

	/*  INITIALIZE THE CIRCULAR HOLDING BUFFER  */
	//initCircBuff();
	temperature = TEMPERATURE_DEF;

	current = inputParameters;

	printf("tube.c:initializeSynthesizer(): SampleRate is %f control period is %d control rate is %f \n",
			controlRate * controlPeriod, controlPeriod, controlRate); //sampleRate);

	outputPeriod = 1 / outputRate;
	printf("tube.c:initializeSynthesizer(): outputPeriod is %f\n", outputPeriod);

	initResult = pthread_create(&tubeThread, NULL, synthesize, NULL);
	if (initResult != 0) {
		printf("tube.c:initializeSynthesizer(): Could not create synthesis thread -- error is %d/%s\n", initResult, strerror(initResult));
		return ERROR;
	}
	printf("tube.c:initializeSynthesizer(): Thread created.\n");

	struct timespec pause = { 0, 50000000 }; // 50 ms
	while (getTubeThreadFlag() != TUBE_THREAD_FLAG_RUNNING) {
		nanosleep(&pause, NULL);
	}
	printf("tube.c:initializeSynthesizer(): Thread running.\n");

	tubeThreadStatus = TUBE_THREAD_STATUS_STARTED;
	return SUCCESS;
}

void tube_stopSynthesizer()
{
	int stopResult = stopTubeThread();
	if (stopResult != 0) {
		printf("tube.c:stopSynthesizer(): Could not stop synthesis thread -- error is %d/%s\n", stopResult, strerror(stopResult));
		return;
	}

	printf("tube.c:stopSynthesizer(): Thread stopped.\n");
	tubeThreadStatus = TUBE_THREAD_STATUS_STOPPED;
}

/******************************************************************************
*
*	function:	initializeWavetable
*
*	purpose:	Calculates the initial glottal pulse and stores it
*                       in the wavetable, for use in the oscillator.
*
*       arguments:      none
*
*	internal
*	functions:	none
*
*	library
*	functions:	calloc, rint
*
******************************************************************************/

void initializeWavetable(void)
{
    int i, j;


    /*  ALLOCATE MEMORY FOR WAVETABLE  */
    //wavetable = (double *)calloc(TABLE_LENGTH, sizeof(double));
	printf("In tube init wavetable Tp is %f, TnMin is %f and TnMax is %f\n", tp, tnMin, tnMax);
    /*  CALCULATE WAVE TABLE PARAMETERS  */
    tableDiv1 = rint(TABLE_LENGTH * (tp / 100.0));
    tableDiv2 = rint(TABLE_LENGTH * ((tp + tnMax) / 100.0)); // **** works for tnMax but not if tnMin is substituted?
	printf("tableDiv1 is %d tableDiv2 is %d\n", tableDiv1, tableDiv2);
    tnLength = tableDiv2 - tableDiv1;
    tnDelta = rint(TABLE_LENGTH * ((tnMax - tnMin) / 100.0));
    basicIncrement = (double)TABLE_LENGTH / (double)sampleRate;
    currentPosition = 0;

    /*  INITIALIZE THE WAVETABLE WITH EITHER A GLOTTAL PULSE OR SINE TONE  */
    if (waveform == PULSE) {
	/*  CALCULATE RISE PORTION OF WAVE TABLE  */
	for (i = 0; i < tableDiv1; i++) {
	    double x = (double)i / (double)tableDiv1;
	    double x2 = x * x;
	    double x3 = x2 * x;
	    wavetable[i] = (3.0 * x2) - (2.0 * x3);
	}

	/*  CALCULATE FALL PORTION OF WAVE TABLE  */
	for (i = tableDiv1, j = 0; i < tableDiv2; i++, j++) {
	    double x = (double)j / tnLength;
	    wavetable[i] = 1.0 - (x * x);
	}

	/*  SET CLOSED PORTION OF WAVE TABLE  */
	for (i = tableDiv2; i < TABLE_LENGTH; i++)
	    wavetable[i] = 0.0;
    }
    else {
	/*  SINE WAVE  */
	for (i = 0; i < TABLE_LENGTH; i++) {
	    wavetable[i] = sin( ((double)i/(double)TABLE_LENGTH) * 2.0 * PI );
	}
    }
}



/******************************************************************************
*
*	function:	updateWavetable
*
*	purpose:	Rewrites the changeable part of the glottal pulse
*                       according to the amplitude.
*
*       arguments:      amplitude
*
*	internal
*	functions:	none
*
*	library
*	functions:	rint
*
******************************************************************************/

void updateWavetable(double amplitude)
{
    int i, j;

	//printf("\nUpdating wavetable tube:664 amplitude is %f \n", amplitude);
    /*  CALCULATE NEW CLOSURE POINT, BASED ON AMPLITUDE  */
    double newDiv2 = tableDiv2 - rint(amplitude * tnDelta);
    double newTnLength = newDiv2 - tableDiv1;
    //printf("Values in updateWavetable tube.c: for i, %d newDiv2 %d, and tableDiv2 %d are:", i, newDiv2, tableDiv2);

    /*  RECALCULATE THE FALLING PORTION OF THE GLOTTAL PULSE  */
    for (i = tableDiv1, j = 0; i < newDiv2; i++, j++) {
	double x = (double)j / newTnLength;
	wavetable[i] = 1.0 - (x * x);
    }

    /*  FILL IN WITH CLOSED PORTION OF GLOTTAL PULSE  */
	for (i = newDiv2; i < tableDiv2; i++)
	wavetable[i] = 0.0;
}



/******************************************************************************
*
*	function:	initializeFIR
*
*	purpose:	Allocates memory and initializes the coefficients
*                       for the FIR filter used in the oversampling oscillator.
*
*       arguments:      beta, gamma, cutoff
*
*	internal
*	functions:	maximallyFlat, trim
*
*	library
*	functions:	calloc
*
******************************************************************************/

void initializeFIR(double beta, double gamma, double cutoff)
{
    int i, pointer, increment, numberCoefficients;
    double coefficient[LIMIT+1];


    /*  DETERMINE IDEAL LOW PASS FILTER COEFFICIENTS  */
    maximallyFlat(beta, gamma, &numberCoefficients, coefficient);

    /*  TRIM LOW-VALUE COEFFICIENTS  */
    trim(cutoff, &numberCoefficients, coefficient);

    /*  DETERMINE THE NUMBER OF TAPS IN THE FILTER  */
    numberTaps = (numberCoefficients * 2) - 1;

    /*  ALLOCATE MEMORY FOR DATA AND COEFFICIENTS  */
    FIRData = (double *)calloc(numberTaps, sizeof(double));
    FIRCoef = (double *)calloc(numberTaps, sizeof(double));

    /*  INITIALIZE THE COEFFICIENTS  */
    increment = (-1);
    pointer = numberCoefficients;
    for (i = 0; i < numberTaps; i++) {
	FIRCoef[i] = coefficient[pointer];
	pointer += increment;
	if (pointer <= 0) {
	    pointer = 2;
	    increment = 1;
	}
    }

    /*  SET POINTER TO FIRST ELEMENT  */
    FIRPtr = 0;

#if DEBUG_TUBE
    /*  PRINT OUT  */
    printf("\n");
    for (i = 0; i < numberTaps; i++)
	printf("FIRCoef[%-d] = %11.8f\n", i, FIRCoef[i]);
#endif
}



/******************************************************************************
*
*	function:	noise
*
*	purpose:	Returns one value of a random sequence.
*
*       arguments:      none
*
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

double noise(void)
{
    static double seed = INITIAL_SEED;

    double product = seed * FACTOR;
    seed = product - (int)product;
    return (seed - 0.5);
}



/******************************************************************************
*
*	function:	noiseFilter
*
*	purpose:	One-zero lowpass filter.
*
*       arguments:      input
*
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

double noiseFilter(double input)
{
    static double noiseX = 0.0;

    double output = input + noiseX;
    noiseX = input;
    return (output);
}



/******************************************************************************
*
*	function:	initializeMouthCoefficients
*
*	purpose:	Calculates the reflection/radiation filter coefficients
*                       for the mouth, according to the mouth aperture
*                       coefficient.
*
*       arguments:      coeff - mouth aperture coefficient
*
*	internal
*	functions:	none
*
*	library
*	functions:	fabs
*
******************************************************************************/

void initializeMouthCoefficients(double coeff)
{
    b11 = -coeff;
    a10 = 1.0 - fabs(b11);

    a20 = coeff;
    a21 = b21 = -a20;
}



/******************************************************************************
*
*	function:	reflectionFilter
*
*	purpose:	Is a variable, one-pole lowpass filter, whose cutoff
*                       is determined by the mouth aperture coefficient.
*
*       arguments:      input
*
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

double reflectionFilter(double input)
{
    static double reflectionY = 0.0;

    double output = (a10 * input) - (b11 * reflectionY);
    reflectionY = output;
    return (output);
}



/******************************************************************************
*
*	function:	radiationFilter
*
*	purpose:	Is a variable, one-zero, one-pole, highpass filter,
*                       whose cutoff point is determined by the mouth aperture
*                       coefficient.
*
*       arguments:      input
*
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

double radiationFilter(double input)
{
    static double radiationX = 0.0, radiationY = 0.0;

    double output = (a20 * input) + (a21 * radiationX) - (b21 * radiationY);
    radiationX = input;
    radiationY = output;
    return (output);
}



/******************************************************************************
*
*	function:	initializeNasalFilterCoefficients
*
*	purpose:	Calculates the fixed coefficients for the nasal
*                       reflection/radiation filter pair, according to the
*                       nose aperture coefficient.
*
*       arguments:      coeff - nose aperture coefficient
*
*	internal
*	functions:	none
*
*	library
*	functions:	fabs
*
******************************************************************************/

void initializeNasalFilterCoefficients(double coeff)
{
    nb11 = -coeff;
    na10 = 1.0 - fabs(nb11);

    na20 = coeff;
    na21 = nb21 = -na20;
}



/******************************************************************************
*
*	function:	nasalReflectionFilter
*
*	purpose:	Is a one-pole lowpass filter, used for terminating
*                       the end of the nasal cavity.
*
*       arguments:      input
*
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

double nasalReflectionFilter(double input)
{
    static double nasalReflectionY = 0.0;

    double output = (na10 * input) - (nb11 * nasalReflectionY);
    nasalReflectionY = output;
    return (output);
}



/******************************************************************************
*
*	function:	nasalRadiationFilter
*
*	purpose:	Is a one-zero, one-pole highpass filter, used for the
*                       radiation characteristic from the nasal cavity.
*
*       arguments:      input
*
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

double nasalRadiationFilter(double input)
{
    static double nasalRadiationX = 0.0, nasalRadiationY = 0.0;

    double output = (na20 * input) + (na21 * nasalRadiationX) -
	(nb21 * nasalRadiationY);
    nasalRadiationX = input;
    nasalRadiationY = output;
    return (output);
}



/******************************************************************************
*
*	function:	synthesize
*
*	purpose:	Performs the actual synthesis of sound samples.
*
*       arguments:      none
*
*	internal
*	functions:	setControlRateParameters, frequency, amplitude,
*                       calculateTubeCoefficients, noise, noiseFilter,
*                       updateWavetable, oscillator, vocalTract, throat,
*                       dataFill, sampleRateInterpolation
*
*	library
*	functions:	none
*
******************************************************************************/

void* synthesize()
{
	double f0, ax, ah1, pulse, lp_noise, pulsed_noise, crossmix, signal;
	int n;

	/*  SAMPLE RATE LOOP TO FILL BUFFER FOR Core Audio IOProc  */

	//initCircBuff();

	setTubeThreadFlag(TUBE_THREAD_FLAG_RUNNING);
	printf("tube.c:synthesize(): Tube thread running.\n");

	for (;;) {
		setControlPeriodParameters();

		for (n = 0; n < controlPeriod; n++) {

			/*  CONVERT PARAMETERS HERE  */
			f0 = frequency(current.glotPitch);
			ax = amplitude(current.glotVol);

			//if (j == 10) {
			//	printf("current.glotVol is %f, ax is %f, j is %d", current.glotVol, ax, j);
			//}

			ah1 = amplitude(current.aspVol);
			//printf("Current ah1 is %f", current.aspVol);

			initializeNasalCavity();
			calculateTubeCoefficients();
			setFricationTaps();
			calculateBandpassCoefficients();

			/*  DO SYNTHESIS HERE  */
			/*  CREATE LOW-PASS FILTERED NOISE  */
			lp_noise = noiseFilter(noise());

			/*  UPDATE THE SHAPE OF THE GLOTTAL PULSE, IF NECESSARY  */

			if (waveform == PULSE) updateWavetable(ax);

			/*  CREATE GLOTTAL PULSE (OR SINE TONE) by sampling wavetable in oscillator()  */
			pulse = oscillator(f0);

			/*  CREATE PULSED NOISE  */
			pulsed_noise = lp_noise * pulse;

			/*  CREATE NOISY GLOTTAL PULSE  */
			pulse = ax * ((pulse * (1.0 - breathinessFactor)) + (pulsed_noise * breathinessFactor));

			/*  CROSS-MIX PURE NOISE WITH PULSED NOISE  */
			if (modulation) {
				crossmix = ax * crossmixFactor;
				crossmix = (crossmix < 1.0) ? crossmix : 1.0;
				signal = (pulsed_noise * crossmix) + (lp_noise * (1.0 - crossmix));
			} else {
				signal = lp_noise;
			}

			/*  PUT SIGNAL THROUGH VOCAL TRACT  */
			signal = vocalTract(((pulse + (ah1 * signal)) * VT_SCALE), bandpassFilter(signal));

			/*  PUT PULSE THROUGH THROAT  */
			signal += throat(pulse * VT_SCALE);

			//printf("gsignal b4 %f     ", gsignal);

			signal = signal * 100;

			// RESAMPLE SUCCESSIVE VALUES FROM TUBE SAMPLE RATE TO OUTPUT SAMPLE RATE
			dataFill(signal);

			originalTime += originalPeriod;

			sampleRateInterpolation();
		}

		if (getTubeThreadFlag() != TUBE_THREAD_FLAG_RUNNING) {
			break;
		}
	}

	printf("tube.c: Tube thread exiting.\n");
	return NULL;
}

void setControlPeriodParameters()
{
	int i;
	float invControlPeriod = 1.0f / controlPeriod;

	parametersDelta.glotPitch = (inputParameters.glotPitch - current.glotPitch) * invControlPeriod;
	parametersDelta.glotVol   = (inputParameters.glotVol   - current.glotVol  ) * invControlPeriod;
	parametersDelta.aspVol    = (inputParameters.aspVol    - current.aspVol   ) * invControlPeriod;
	parametersDelta.fricVol   = (inputParameters.fricVol   - current.fricVol  ) * invControlPeriod;
	parametersDelta.fricPos   = (inputParameters.fricPos   - current.fricPos  ) * invControlPeriod;
	parametersDelta.fricCF    = (inputParameters.fricCF    - current.fricCF   ) * invControlPeriod;
	parametersDelta.fricBW    = (inputParameters.fricBW    - current.fricBW   ) * invControlPeriod;
	parametersDelta.velum     = (inputParameters.velum     - current.velum    ) * invControlPeriod;
	for (i = 0; i < TOTAL_REGIONS; i++)
		parametersDelta.radius[i]     = (inputParameters.radius[i]     - current.radius[i]    ) * invControlPeriod;
	for (i = 0; i < TOTAL_NASAL_SECTIONS; i++)
		parametersDelta.noseRadius[i] = (inputParameters.noseRadius[i] - current.noseRadius[i]) * invControlPeriod;
}

/******************************************************************************
*
*	function:	sampleRateInterpolation
*
*	purpose:	Interpolates table values at the sample rate.
*
*       arguments:      none
*
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

void sampleRateInterpolation()
{
	int i;
	//printf("Sample rate interp\n");
	current.glotPitch += parametersDelta.glotPitch;
	current.glotVol   += parametersDelta.glotVol;
	current.aspVol    += parametersDelta.aspVol;
	current.fricVol   += parametersDelta.fricVol;
	current.fricPos   += parametersDelta.fricPos;
	current.fricCF    += parametersDelta.fricCF;
	current.fricBW    += parametersDelta.fricBW;
	current.velum     += parametersDelta.velum;
	for (i = 0; i < TOTAL_REGIONS; i++)
		current.radius[i]     += parametersDelta.radius[i];
	for (i = 0; i < TOTAL_NASAL_SECTIONS; i++)
		current.noseRadius[i] += parametersDelta.noseRadius[i];
	//printf("current radius R5 is %f", current.radius[4]);
}



/******************************************************************************
*
*	function:	initializeNasalCavity
*
*	purpose:	Calculates the scattering coefficients for the fixed
*                       sections of the nasal cavity.
*
*       arguments:      none
*
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

void initializeNasalCavity(void)
{
    int i, j;
    double radA2, radB2;


    /*  CALCULATE COEFFICIENTS FOR INTERNAL FIXED SECTIONS OF NASAL CAVITY  */
    for (i = N2, j = NC2; i < N6; i++, j++) {
	radA2 = current.noseRadius[i] * current.noseRadius[i];
	radB2 = current.noseRadius[i+1] * current.noseRadius[i+1];
	nasal_coeff[j] = (radA2 - radB2) / (radA2 + radB2);
    }

    /*  CALCULATE THE FIXED COEFFICIENT FOR THE NOSE APERTURE  */
    radA2 = current.noseRadius[N6] * current.noseRadius[N6];
    radB2 = apScale * apScale;
    nasal_coeff[NC6] = (radA2 - radB2) / (radA2 + radB2);
}



/******************************************************************************
*
*	function:	initializeThroat
*
*	purpose:	Initializes the throat lowpass filter coefficients
*                       according to the throatCutoff value, and also the
*                       throatGain, according to the throatVol value.
*
*       arguments:      none
*
*	internal
*	functions:	none
*
*	library
*	functions:	fabs
*
******************************************************************************/

void initializeThroat(void)
{
    ta0 = (throatCutoff * 2.0)/sampleRate;
    tb1 = 1.0 - ta0;

    throatGain = amplitude(throatVol);
}



/******************************************************************************
*
*	function:	calculateTubeCoefficients
*
*	purpose:	Calculates the scattering coefficients for the vocal
*                       tract according to the current radii.  Also calculates
*                       the coefficients for the reflection/radiation filter
*                       pair for the mouth and nose.
*
*       arguments:      none
*
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

void calculateTubeCoefficients(void)
{
    int i;
    double radA2, radB2, r0_2, r1_2, r2_2, sum;


    /*  CALCULATE COEFFICIENTS FOR THE OROPHARYNX  */
    for (i = 0; i < (TOTAL_REGIONS-1); i++) {
	radA2 = current.radius[i] * current.radius[i];
	radB2 = current.radius[i+1] * current.radius[i+1];
	oropharynx_coeff[i] = (radA2 - radB2) / (radA2 + radB2);
    }

    /*  CALCULATE THE COEFFICIENT FOR THE MOUTH APERTURE  */
    radA2 = current.radius[R8] * current.radius[R8];
    radB2 = apScale * apScale;
    oropharynx_coeff[C8] = (radA2 - radB2) / (radA2 + radB2);

    /*  CALCULATE ALPHA COEFFICIENTS FOR 3-WAY JUNCTION  */
    /*  NOTE:  SINCE JUNCTION IS IN MIDDLE OF REGION 4, r0_2 = r1_2  */
    r0_2 = r1_2 = current.radius[R4] * current.radius[R4];
    r2_2 = current.velum * current.velum;
    sum = 2.0 / (r0_2 + r1_2 + r2_2);
    alpha[LEFT] = sum * r0_2;
    alpha[RIGHT] = sum * r1_2;
    alpha[UPPER] = sum * r2_2;

    /*  AND 1ST NASAL PASSAGE COEFFICIENT  */
    radA2 = current.velum * current.velum;
	//printf("current.velum is %f", current.velum);
    radB2 = current.noseRadius[N2] * current.noseRadius[N2];
    nasal_coeff[NC1] = (radA2 - radB2) / (radA2 + radB2);
}



/******************************************************************************
*
*	function:	setFricationTaps
*
*	purpose:	Sets the frication taps according to the current
*                       position and amplitude of frication.
*
*       arguments:      none
*
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

void setFricationTaps(void)
{
    int i, integerPart;
    double complement, remainder;
    double fricationAmplitude = amplitude(current.fricVol);
	//printf("tube.c: frication amplitude is %f, current.fricvol %f", fricationAmplitude, current.fricVol);
	//printf("tube.c: fricPos is %f", current.fricPos);

    /*  CALCULATE POSITION REMAINDER AND COMPLEMENT  */
    integerPart = (int)current.fricPos;
    complement = current.fricPos - (double)integerPart;
    remainder = 1.0 - complement;
	//printf("tube.c: complement is %f, remainder is %f", complement, remainder);

    /*  SET THE FRICATION TAPS  */
    for (i = FC1; i < TOTAL_FRIC_COEFFICIENTS; i++) {
	if (i == integerPart) {
	    fricationTap[i] = remainder * fricationAmplitude;
	    if ((i+1) < TOTAL_FRIC_COEFFICIENTS)
		fricationTap[++i] = complement * fricationAmplitude;
	}
	else
	    fricationTap[i] = 0.0;
    }

#if DEBUG_TUBE
    /*  PRINT OUT  */
    printf("fricationTaps:  ");
    for (i = FC1; i < TOTAL_FRIC_COEFFICIENTS; i++)
	printf("%.6f  ", fricationTap[i]);
    printf("\n");
#endif
}



/******************************************************************************
*
*	function:	calculateBandpassCoefficients
*
*	purpose:	Sets the frication bandpass filter coefficients
*                       according to the current center frequency and
*                       bandwidth.
*
*       arguments:      none
*
*	internal
*	functions:	none
*
*	library
*	functions:	tan, cos
*
******************************************************************************/

void calculateBandpassCoefficients(void)
{
    double tanValue, cosValue;


    tanValue = tan((PI * current.fricBW) / sampleRate);
    cosValue = cos((2.0 * PI * current.fricCF) / sampleRate);

    bpBeta = (1.0 - tanValue) / (2.0 * (1.0 + tanValue));
    bpGamma = (0.5 + bpBeta) * cosValue;
    bpAlpha = (0.5 - bpBeta) / 2.0;
}



/******************************************************************************
*
*	function:	mod0
*
*	purpose:	Returns the modulus of 'value', keeping it in the
*                       range 0 -> TABLE_MODULUS.
*
*       arguments:      value
*
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

double mod0(double value)
{
    if (value > TABLE_MODULUS)
	value -= TABLE_LENGTH;

    return (value);
}



/******************************************************************************
*
*	function:	incrementTablePosition
*
*	purpose:	Increments the position in the wavetable according to
*                       the desired frequency.
*
*       arguments:      frequency
*
*	internal
*	functions:	mod0
*
*	library
*	functions:	none
*
*	Crafty use of mod0() to wrap the currentPosition around at about 510
*	to keep in bounds of wavetable while repeating.  mod0(value) Returns the
*	modulus of 'value', keeping it in the range 0 -> TABLE_MODULUS.
*
*
******************************************************************************/

void incrementTablePosition(double frequency)
{
	double temp = currentPosition;
    currentPosition = mod0(currentPosition + (frequency * basicIncrement));
	if (currentPosition < temp)
		pitchFlag = 1;
	else pitchFlag = 0;
}



/******************************************************************************
*
*	function:	oscillator
*
*	purpose:	Is a 2X oversampling interpolating wavetable
*                       oscillator.
*
*       arguments:      frequency
*
*	internal
*	functions:	incrementTablePosition, mod0, FIRFilter
*
*	library
*	functions:	none
*
******************************************************************************/

#if OVERSAMPLING_OSCILLATOR
double oscillator(double frequency)  /*  2X OVERSAMPLING OSCILLATOR  */
{
    int i, lowerPosition, upperPosition;
    double interpolatedValue, output;


    for (i = 0; i < 2; i++) {
	/*  FIRST INCREMENT THE TABLE POSITION, DEPENDING ON FREQUENCY  */
	incrementTablePosition(frequency/2.0); // ****

	/*  FIND SURROUNDING INTEGER TABLE POSITIONS  */
	lowerPosition = (int)currentPosition;
	upperPosition = mod0(lowerPosition + 1);

	/*  CALCULATE INTERPOLATED TABLE VALUE  */
	interpolatedValue = (wavetable[lowerPosition] +
			     ((currentPosition - lowerPosition) *
			      (wavetable[upperPosition] -
			       wavetable[lowerPosition])));

	/*  PUT VALUE THROUGH FIR FILTER  */
	output = FIRFilter(interpolatedValue, i);
    }

    /*  SINCE WE DECIMATE, TAKE ONLY THE SECOND OUTPUT VALUE  */
    return (output);
}
#else
double oscillator(double frequency)  /*  PLAIN OSCILLATOR  */
{
    int lowerPosition, upperPosition;


    /*  FIRST INCREMENT THE TABLE POSITION, DEPENDING ON FREQUENCY  */
    incrementTablePosition(frequency);

    /*  FIND SURROUNDING INTEGER TABLE POSITIONS  */
    lowerPosition = (int)currentPosition;
    upperPosition = mod0(lowerPosition + 1);

/*  RETURN INTERPOLATED TABLE VALUE  */
    return (wavetable[lowerPosition] +
	    ((currentPosition - lowerPosition) *
	     (wavetable[upperPosition] - wavetable[lowerPosition])));
}
#endif



/******************************************************************************
*
*	function:	vocalTract
*
*	purpose:	Updates the pressure wave throughout the vocal tract,
*                       and returns the summed output of the oral and nasal
*                       cavities.  Also injects frication appropriately.
*
*       arguments:      input, frication
*
*	internal
*	functions:	reflectionFilter, radiationFilter,
*                       nasalReflectionFilter, nasalRadiationFilter
*
*	library
*	functions:	none
*
******************************************************************************/

double vocalTract(double input, double frication)
{
    int i, j, k;
    double delta, output, junctionPressure;


    /*  INCREMENT CURRENT AND PREVIOUS POINTERS  */
    if (++current_ptr > 1)
	current_ptr = 0;
    if (++prev_ptr > 1)
	prev_ptr = 0;

    /*  UPDATE OROPHARYNX  */
    /*  INPUT TO TOP OF TUBE  */
    oropharynx[S1][TOP][current_ptr] =
	(oropharynx[S1][BOTTOM][prev_ptr] * dampingFactor) + input;

    /*  CALCULATE THE SCATTERING JUNCTIONS FOR S1-S2  */
    delta = oropharynx_coeff[C1] *
	(oropharynx[S1][TOP][prev_ptr] - oropharynx[S2][BOTTOM][prev_ptr]);
    oropharynx[S2][TOP][current_ptr] =
	(oropharynx[S1][TOP][prev_ptr] + delta) * dampingFactor;
    oropharynx[S1][BOTTOM][current_ptr] =
	(oropharynx[S2][BOTTOM][prev_ptr] + delta) * dampingFactor;

    /*  CALCULATE THE SCATTERING JUNCTIONS FOR S2-S3 AND S3-S4  */
    for (i = S2, j = C2, k = FC1; i < S4; i++, j++, k++) {
	delta = oropharynx_coeff[j] *
	    (oropharynx[i][TOP][prev_ptr] - oropharynx[i+1][BOTTOM][prev_ptr]);
	oropharynx[i+1][TOP][current_ptr] =
	    ((oropharynx[i][TOP][prev_ptr] + delta) * dampingFactor) +
		(fricationTap[k] * frication);
	oropharynx[i][BOTTOM][current_ptr] =
	    (oropharynx[i+1][BOTTOM][prev_ptr] + delta) * dampingFactor;
    }

    /*  UPDATE 3-WAY JUNCTION BETWEEN THE MIDDLE OF R4 AND NASAL CAVITY  */
    junctionPressure = (alpha[LEFT] * oropharynx[S4][TOP][prev_ptr])+
	(alpha[RIGHT] * oropharynx[S5][BOTTOM][prev_ptr]) +
	(alpha[UPPER] * nasal[VELUM][BOTTOM][prev_ptr]);
    oropharynx[S4][BOTTOM][current_ptr] =
	(junctionPressure - oropharynx[S4][TOP][prev_ptr]) * dampingFactor;
    oropharynx[S5][TOP][current_ptr] =
	((junctionPressure - oropharynx[S5][BOTTOM][prev_ptr]) * dampingFactor)
	    + (fricationTap[FC3] * frication);
    nasal[VELUM][TOP][current_ptr] =
	(junctionPressure - nasal[VELUM][BOTTOM][prev_ptr]) * dampingFactor;

    /*  CALCULATE JUNCTION BETWEEN R4 AND R5 (S5-S6)  */
    delta = oropharynx_coeff[C4] *
	(oropharynx[S5][TOP][prev_ptr] - oropharynx[S6][BOTTOM][prev_ptr]);
    oropharynx[S6][TOP][current_ptr] =
	((oropharynx[S5][TOP][prev_ptr] + delta) * dampingFactor) +
	    (fricationTap[FC4] * frication);
    oropharynx[S5][BOTTOM][current_ptr] =
	(oropharynx[S6][BOTTOM][prev_ptr] + delta) * dampingFactor;

    /*  CALCULATE JUNCTION INSIDE R5 (S6-S7) (PURE DELAY WITH DAMPING)  */
    oropharynx[S7][TOP][current_ptr] =
	(oropharynx[S6][TOP][prev_ptr] * dampingFactor) +
	    (fricationTap[FC5] * frication);
    oropharynx[S6][BOTTOM][current_ptr] =
	oropharynx[S7][BOTTOM][prev_ptr] * dampingFactor;

    /*  CALCULATE LAST 3 INTERNAL JUNCTIONS (S7-S8, S8-S9, S9-S10)  */
    for (i = S7, j = C5, k = FC6; i < S10; i++, j++, k++) {
	delta = oropharynx_coeff[j] *
	    (oropharynx[i][TOP][prev_ptr] - oropharynx[i+1][BOTTOM][prev_ptr]);
	oropharynx[i+1][TOP][current_ptr] =
	    ((oropharynx[i][TOP][prev_ptr] + delta) * dampingFactor) +
		(fricationTap[k] * frication);
	oropharynx[i][BOTTOM][current_ptr] =
	    (oropharynx[i+1][BOTTOM][prev_ptr] + delta) * dampingFactor;
    }

    /*  REFLECTED SIGNAL AT MOUTH GOES THROUGH A LOWPASS FILTER  */
    oropharynx[S10][BOTTOM][current_ptr] =  dampingFactor *
	reflectionFilter(oropharynx_coeff[C8] *
			 oropharynx[S10][TOP][prev_ptr]);

    /*  OUTPUT FROM MOUTH GOES THROUGH A HIGHPASS FILTER  */
    output = radiationFilter((1.0 + oropharynx_coeff[C8]) *
			     oropharynx[S10][TOP][prev_ptr]);


    /*  UPDATE NASAL CAVITY  */
    for (i = VELUM, j = NC1; i < N6; i++, j++) {
	delta = nasal_coeff[j] *
	    (nasal[i][TOP][prev_ptr] - nasal[i+1][BOTTOM][prev_ptr]);
	nasal[i+1][TOP][current_ptr] =
	    (nasal[i][TOP][prev_ptr] + delta) * dampingFactor;
	nasal[i][BOTTOM][current_ptr] =
	    (nasal[i+1][BOTTOM][prev_ptr] + delta) * dampingFactor;
    }

    /*  REFLECTED SIGNAL AT NOSE GOES THROUGH A LOWPASS FILTER  */
    nasal[N6][BOTTOM][current_ptr] = dampingFactor *
	nasalReflectionFilter(nasal_coeff[NC6] * nasal[N6][TOP][prev_ptr]);

    /*  OUTPUT FROM NOSE GOES THROUGH A HIGHPASS FILTER  */
    output += nasalRadiationFilter((1.0 + nasal_coeff[NC6]) *
				   nasal[N6][TOP][prev_ptr]);

    /*  RETURN SUMMED OUTPUT FROM MOUTH AND NOSE  */
    return(output);
}



/******************************************************************************
*
*	function:	throat
*
*	purpose:	Simulates the radiation of sound through the walls
*                       of the throat.  Note that this form of the filter
*                       uses addition instead of subtraction for the
*                       second term, since tb1 has reversed sign.
*
*       arguments:      input
*
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

double throat(double input)
{
    static double throatY = 0.0;

    double output = (ta0 * input) + (tb1 * throatY);
    throatY = output;
    return (output * throatGain);
}



/******************************************************************************
*
*	function:	bandpassFilter
*
*	purpose:	Frication bandpass filter, with variable center
*                       frequency and bandwidth.
*
*       arguments:      input
*
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

double bandpassFilter(double input)
{
    static double xn1 = 0.0, xn2 = 0.0, yn1 = 0.0, yn2 = 0.0;
    double output;


    output = 2.0 *
	((bpAlpha * (input - xn2)) + (bpGamma * yn1) - (bpBeta * yn2));

    xn2 = xn1;
    xn1 = input;
    yn2 = yn1;
    yn1 = output;

    return (output);
}



/******************************************************************************
*
*       function:       amplitude
*
*       purpose:        Converts dB value to amplitude value.
*
*       internal
*       functions:      none
*
*       library
*       functions:      pow
*
******************************************************************************/

double amplitude(double decibelLevel)
{
	//printf("Value passed to amplitude() tube.c: is %f", decibelLevel);
    /*  CONVERT 0-60 RANGE TO -60-0 RANGE  */
    decibelLevel -= VOL_MAX;

    /*  IF -60 OR LESS, RETURN AMPLITUDE OF 0  */
    if (decibelLevel <= (-VOL_MAX))
        return(0.0);

    /*  IF 0 OR GREATER, RETURN AMPLITUDE OF 1  */
    if (decibelLevel >= 0.0)
        return(1.0);

    /*  ELSE RETURN INVERSE LOG VALUE  */
    return(pow(10.0,(decibelLevel/20.0)));
}



/******************************************************************************
*
*       function:       frequency
*
*       purpose:        Converts a given pitch (0 = middle C) to the
*                       corresponding frequency.
*
*       internal
*       functions:      none
*
*       library
*       functions:      pow
*
******************************************************************************/

double frequency(double pitch)
{
    return(PITCH_BASE * pow(2.0,(((double)(pitch+PITCH_OFFSET))/12.0)));
}



/******************************************************************************
*
*	function:	maximallyFlat
*
*	purpose:	Calculates coefficients for a linear phase lowpass FIR
*                       filter, with beta being the center frequency of the
*                       transition band (as a fraction of the sampling
*                       frequency), and gamme the width of the transition
*                       band.
*
*       arguments:      beta, gamma, np, coefficient
*
*	internal
*	functions:	rationalApproximation
*
*	library
*	functions:	cos, pow
*
******************************************************************************/

int maximallyFlat(double beta, double gamma, int *np, double *coefficient)
{
    double a[LIMIT+1], c[LIMIT+1], betaMinimum, ac;
    int nt, numerator, n, ll, i;


    /*  INITIALIZE NUMBER OF POINTS  */
    (*np) = 0;

    /*  CUT-OFF FREQUENCY MUST BE BETWEEN 0 HZ AND NYQUIST  */
    if ((beta <= 0.0) || (beta >= 0.5))
	return(BETA_OUT_OF_RANGE);

    /*  TRANSITION BAND MUST FIT WITH THE STOP BAND  */
    betaMinimum = ((2.0 * beta) < (1.0 - 2.0 * beta)) ? (2.0 * beta) :
	(1.0 - 2.0 * beta);
    if ((gamma <= 0.0) || (gamma >= betaMinimum))
	return(GAMMA_OUT_OF_RANGE);

    /*  MAKE SURE TRANSITION BAND NOT TOO SMALL  */
    nt = (int)(1.0 / (4.0 * gamma * gamma));
    if (nt > 160)
	return(GAMMA_TOO_SMALL);

    /*  CALCULATE THE RATIONAL APPROXIMATION TO THE CUT-OFF POINT  */
    ac = (1.0 + cos(PI2 * beta)) / 2.0;
    rationalApproximation(ac, &nt, &numerator, np);

    /*  CALCULATE FILTER ORDER  */
    n = (2 * (*np)) - 1;
    if (numerator == 0)
	numerator = 1;


    /*  COMPUTE MAGNITUDE AT NP POINTS  */
    c[1] = a[1] = 1.0;
    ll = nt - numerator;

    for (i = 2; i <= (*np); i++) {
	int j;
	double x, sum = 1.0, y;
	c[i] = cos(PI2 * ((double)(i-1)/(double)n));
	x = (1.0 - c[i]) / 2.0;
	y = x;

	if (numerator == nt)
	    continue;

	for (j = 1; j <= ll; j++) {
	    double z = y;
	    if (numerator != 1) {
		int jj;
		for (jj = 1; jj <= (numerator - 1); jj++)
		    z *= 1.0 + ((double)j / (double)jj);
	    }
	    y *= x;
	    sum += z;
	}
	a[i] = sum * pow((1.0 - x), numerator);
    }


    /*  CALCULATE WEIGHTING COEFFICIENTS BY AN N-POINT IDFT  */
    for (i = 1; i <= (*np); i++) {
	int j;
	coefficient[i] = a[1] / 2.0;
	for (j = 2; j <= (*np); j++) {
	    int m = ((i - 1) * (j - 1)) % n;
	    if (m > nt)
		m = n - m;
	    coefficient[i] += c[m+1] * a[j];
	}
	coefficient[i] *= 2.0/(double)n;
    }

    return(0);
}



/******************************************************************************
*
*	function:	trim
*
*	purpose:	Trims the higher order coefficients of the FIR filter
*                       which fall below the cutoff value.
*
*       arguments:      cutoff, numberCoefficients, coefficient
*
*	internal
*	functions:	none
*
*	library
*	functions:	fabs
*
******************************************************************************/

void trim(double cutoff, int *numberCoefficients, double *coefficient)
{
    int i;

    for (i = (*numberCoefficients); i > 0; i--) {
	if (fabs(coefficient[i]) >= fabs(cutoff)) {
	    (*numberCoefficients) = i;
	    return;
	}
    }
}



/******************************************************************************
*
*	function:	rationalApproximation
*
*	purpose:	Calculates the best rational approximation to 'number',
*                       given the maximum 'order'.
*
*       arguments:      number, order, numerator, denominator
*
*	internal
*	functions:	none
*
*	library
*	functions:	fabs
*
******************************************************************************/

void rationalApproximation(double number, int *order,
			   int *numerator, int *denominator)
{
    double fractionalPart, minimumError = 1.0;
    int i, orderMaximum, modulus = 0;


    /*  RETURN IMMEDIATELY IF THE ORDER IS LESS THAN ONE  */
    if (*order <= 0) {
	*numerator = 0;
	*denominator = 0;
	*order = -1;
	return;
    }

    /*  FIND THE ABSOLUTE VALUE OF THE FRACTIONAL PART OF THE NUMBER  */
    fractionalPart = fabs(number - (int)number);

    /*  DETERMINE THE MAXIMUM VALUE OF THE DENOMINATOR  */
    orderMaximum = 2 * (*order);
    orderMaximum = (orderMaximum > LIMIT) ? LIMIT : orderMaximum;

    /*  FIND THE BEST DENOMINATOR VALUE  */
    for (i = (*order); i <= orderMaximum; i++) {
	double ps = i * fractionalPart;
	int ip = (int)(ps + 0.5);
	double error = fabs( (ps - (double)ip)/(double)i );
	if (error < minimumError) {
	    minimumError = error;
	    modulus = ip;
	    *denominator = i;
	}
    }

    /*  DETERMINE THE NUMERATOR VALUE, MAKING IT NEGATIVE IF NECESSARY  */
    *numerator = (int)fabs(number) * (*denominator) + modulus;
    if (number < 0)
	*numerator *= (-1);

    /*  SET THE ORDER  */
    *order = *denominator - 1;

    /*  RESET THE NUMERATOR AND DENOMINATOR IF THEY ARE EQUAL  */
    if (*numerator == *denominator) {
	*denominator = orderMaximum;
	*order = *numerator = *denominator - 1;
    }
}



/******************************************************************************
*
*	function:	FIRFilter
*
*	purpose:	Is the linear phase, lowpass FIR filter.
*
*       arguments:      input, needOutput
*
*	internal
*	functions:	increment, decrement
*
*	library
*	functions:	none
*
******************************************************************************/

double FIRFilter(double input, int needOutput)
{
    if (needOutput) {
	int i;
	double output = 0.0;

	/*  PUT INPUT SAMPLE INTO DATA BUFFER  */
	FIRData[FIRPtr] = input;

	/*  SUM THE OUTPUT FROM ALL FILTER TAPS  */
	for (i = 0; i < numberTaps; i++) {
	    output += FIRData[FIRPtr] * FIRCoef[i];
	    FIRPtr = increment(FIRPtr, numberTaps);
	}

	/*  DECREMENT THE DATA POINTER READY FOR NEXT CALL  */
	FIRPtr = decrement(FIRPtr, numberTaps);

	/*  RETURN THE OUTPUT VALUE  */
	return(output);
    }
    else {
	/*  PUT INPUT SAMPLE INTO DATA BUFFER  */
	FIRData[FIRPtr] = input;

	/*  ADJUST THE DATA POINTER, READY FOR NEXT CALL  */
	FIRPtr = decrement(FIRPtr, numberTaps);

	return(0.0);
    }
}



/******************************************************************************
*
*	function:	increment
*
*	purpose:	Increments the pointer to the circular FIR filter
*                       buffer, keeping it in the range 0 -> modulus-1.
*
*       arguments:      pointer, modulus
*
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

int increment(int pointer, int modulus)
{
    if (++pointer >= modulus)
	return(0);
    else
	return(pointer);
}


/******************************************************************************
*
*	function:	decrement
*
*	purpose:	Decrements the pointer to the circular FIR filter
*                       buffer, keeping it in the range 0 -> modulus-1.
*
*       arguments:      pointer, modulus
*
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

int decrement(int pointer, int modulus)
{
    if (--pointer < 0)
	return(modulus-1);
    else
	return(pointer);
}



/******************************************************************************
*
*	function:	initializeConversion
*
*	purpose:	Initializes all the sample rate conversion functions.
*
*       arguments:      none
*
*	internal
*	functions:	initializeFilter, initializeBuffer
*
*	library
*	functions:	rint, pow
*	[apparently not called 2009-01-07]
*
******************************************************************************/

void initializeConversion(void)
{
    double roundedSampleRateRatio;

    timeRegister = 0;
    emptyPtr = 0;

    /*  INITIALIZE FILTER IMPULSE RESPONSE  */
    initializeFilter();

    /*  CALCULATE SAMPLE RATE RATIO  */
    sampleRateRatio = (double)outputRate / (double)sampleRate;
	printf("tube.c: output-rate is: %f, sample rate is: %d, sample rate ratio is: %f\n",outputRate, sampleRate, sampleRateRatio);

    /*  CALCULATE TIME REGISTER INCREMENT  */
    timeRegisterIncrement =
	(int)rint( pow(2.0, FRACTION_BITS) / sampleRateRatio );

    /*  CALCULATE ROUNDED SAMPLE RATE RATIO  */
    roundedSampleRateRatio =
	pow(2.0, FRACTION_BITS) / (double)timeRegisterIncrement;

    /*  CALCULATE PHASE OR FILTER INCREMENT  */
    if (sampleRateRatio >= 1.0) {
	filterIncrement = L_RANGE;
    }
    else {
	phaseIncrement =
	     (unsigned int)rint(sampleRateRatio * (double)FRACTION_RANGE);
    }

    /*  CALCULATE PAD SIZE  */
    padSize = (sampleRateRatio >= 1.0) ? ZERO_CROSSINGS :
	(int)((float)ZERO_CROSSINGS / roundedSampleRateRatio) + 1;

    /*  INITIALIZE THE RING BUFFER  */
    initializeBuffer();
}



/******************************************************************************
*
*	function:	initializeFilter
*
*	purpose:	Initializes filter impulse response and impulse delta
*                       values.
*
*       arguments:      none
*
*	internal
*	functions:	none
*
*	library
*	functions:	sin, cos
*
******************************************************************************/

void initializeFilter(void)
{
    double x, IBeta;
    int i;


    /*  INITIALIZE THE FILTER IMPULSE RESPONSE  */
    h[0] = LP_CUTOFF;
    x = PI / (double)L_RANGE;
    for (i = 1; i < FILTER_LENGTH; i++) {
	double y = (double)i * x;
	h[i] = sin(y * LP_CUTOFF) / y;
    }

    /*  APPLY A KAISER WINDOW TO THE IMPULSE RESPONSE  */
    IBeta = 1.0 / Izero2(BETA);
    for (i = 0; i < FILTER_LENGTH; i++) {
	double temp = (double)i / FILTER_LENGTH;
	h[i] *= Izero2(BETA * sqrt(1.0 - (temp * temp))) * IBeta;
    }

    /*  INITIALIZE THE FILTER IMPULSE RESPONSE DELTA VALUES  */
    for (i = 0; i < FILTER_LIMIT; i++)
	deltaH[i] = h[i+1] - h[i];
    deltaH[FILTER_LIMIT] = 0.0 - h[FILTER_LIMIT];
}



/******************************************************************************
*
*	function:	Izero2
*
*	purpose:	Returns the value for the modified Bessel function of
*                       the first kind, order 0, as a double.
*
*       arguments:      x - input argument
*
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

double Izero2(double x)
{
    double sum, u, halfx, temp;
    int n;


    sum = u = n = 1;
    halfx = x / 2.0;

    do {
	temp = halfx / (double)n;
	n += 1;
	temp *= temp;
	u *= temp;
	sum += u;
    } while (u >= (IzeroEPSILON * sum));

    return(sum);
}



/******************************************************************************
*
*	function:	initializeBuffer
*
*	purpose:	Initializes the ring buffer used for sample rate
*                       conversion.
*
*       arguments:      none
*
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

void initializeBuffer(void)
{
    int i;


    /*  FILL THE RING BUFFER WITH ALL ZEROS  */
    for (i = 0; i < BUFFER_SIZE; i++)
	buffer[i] = 0.0;

    /*  INITIALIZE FILL POINTER  */
    fillPtr = padSize;

    /*  CALCULATE FILL SIZE  */
    fillSize = BUFFER_SIZE - (2 * padSize);
}



/******************************************************************************
*
*	function:	dataFill
*
*	purpose:	Fills the ring buffer with a single sample, increments
*                       the counters and pointers, and empties the buffer when
*                       full.
*
*       arguments:      data
*
*	internal
*	functions:	srIncrement, dataEmpty
*
*	library
*	functions:	none
*
******************************************************************************/

void dataFill(double data)
{
    static int fillCounter = 0;


    /*  PUT THE DATA INTO THE RING BUFFER  */
    buffer[fillPtr] = data;

    /*  INCREMENT THE FILL POINTER, MODULO THE BUFFER SIZE  */
    srIncrement(&fillPtr, BUFFER_SIZE);

    /*  INCREMENT THE COUNTER, AND EMPTY THE BUFFER IF FULL  */
    if (++fillCounter >= fillSize) {
 	dataEmpty();
	/* RESET THE FILL COUNTER  */
	fillCounter = 0;
    }
}



/******************************************************************************
*
*	function:	dataEmpty
*
*	purpose:	Converts available portion of the input signal to the
*                       new sampling rate, and outputs the samples to the
*                       sound struct.
*
*       arguments:      none
*
*	internal
*	functions:	srDecrement, srIncrement
*
*	library
*	functions:	rint, fabs, fwrite
*
******************************************************************************/

void dataEmpty(void)
{
    int endPtr;


    /*  CALCULATE END POINTER  */
    endPtr = fillPtr - padSize;

    /*  ADJUST THE END POINTER, IF LESS THAN ZERO  */
    if (endPtr < 0)
	endPtr += BUFFER_SIZE;

    /*  ADJUST THE ENDPOINT, IF LESS THAN THE EMPTY POINTER  */
    if (endPtr < emptyPtr)
	endPtr += BUFFER_SIZE;

    /*  UPSAMPLE LOOP (SLIGHTLY MORE EFFICIENT THAN DOWNSAMPLING)  */
    if (sampleRateRatio >= 1.0) {
	while (emptyPtr < endPtr) {
	    int index;
	    unsigned int filterIndex;
	    double output, interpolation, absoluteSampleValue;

	    /*  RESET ACCUMULATOR TO ZERO  */
	    output = 0.0;

	    /*  CALCULATE INTERPOLATION VALUE (STATIC WHEN UPSAMPLING)  */
	    interpolation = (double)mValue(timeRegister) / (double)M_RANGE;

	    /*  COMPUTE THE LEFT SIDE OF THE FILTER CONVOLUTION  */
	    index = emptyPtr;
	    for (filterIndex = lValue(timeRegister);
		 filterIndex < FILTER_LENGTH;
		 srDecrement(&index,BUFFER_SIZE),
		 filterIndex += filterIncrement) {
		output += (buffer[index] *
		    (h[filterIndex] + (deltaH[filterIndex] * interpolation)));
	    }

	    /*  ADJUST VALUES FOR RIGHT SIDE CALCULATION  */
	    timeRegister = ~timeRegister;
	    interpolation = (double)mValue(timeRegister) / (double)M_RANGE;

	    /*  COMPUTE THE RIGHT SIDE OF THE FILTER CONVOLUTION  */
	    index = emptyPtr;
	    srIncrement(&index,BUFFER_SIZE);
	    for (filterIndex = lValue(timeRegister);
		 filterIndex < FILTER_LENGTH;
		 srIncrement(&index,BUFFER_SIZE),
		 filterIndex += filterIncrement) {
		output += (buffer[index] *
		    (h[filterIndex] + (deltaH[filterIndex] * interpolation)));
	    }

	    /*  RECORD MAXIMUM SAMPLE VALUE  */
	    absoluteSampleValue = fabs(output);
	    if (absoluteSampleValue > maximumSampleValue)
		maximumSampleValue = absoluteSampleValue;

	    /*  INCREMENT SAMPLE NUMBER  */
	    numberSamples++;

#ifdef GNUSTEP
	    float outputFloat = output;
	    struct timespec pause = { 0, MIN_LATENCY_NS };
	    while (jack_ringbuffer_write_space(jackData.ringBuffer) < sizeof(float)) {
                if (getTubeThreadFlag() == TUBE_THREAD_FLAG_EXIT) {
                    return;
                }
	        nanosleep(&pause, NULL);
	    }
	    size_t bytesWritten = jack_ringbuffer_write(jackData.ringBuffer, (const char*) &outputFloat, sizeof(float));
	    assert(bytesWritten == sizeof(float));

	    putCircBuff(outputFloat);
#else
		// OUTPUT SAMPLE TO CIRCBUFF2
		pthread_mutex_lock (&circBuff2Mutex);
	outWait1: while (circBuff2Flag == FULL) pthread_cond_wait(&circBuff2Cond, &circBuff2Mutex); // if circBuff2 full, sleep & wait
		if (circBuff2Flag == FULL) goto outWait1;
		int failed = putCircBuff2((float)output); // if room, put output in circBuff2
		if (failed) goto outWait1;

		pthread_cond_signal(&circBuff2Cond);
		pthread_mutex_unlock(&circBuff2Mutex);
#endif
		//printf("tube.c: %f  ", output);

	    /*  CHANGE TIME REGISTER BACK TO ORIGINAL FORM  */
	    timeRegister = ~timeRegister;

	    /*  INCREMENT THE TIME REGISTER  */
	    timeRegister += timeRegisterIncrement;

	    /*  INCREMENT THE EMPTY POINTER, ADJUSTING IT AND END POINTER  */
	    emptyPtr += nValue(timeRegister);

	    if (emptyPtr >= BUFFER_SIZE) {
		emptyPtr -= BUFFER_SIZE;
		endPtr -= BUFFER_SIZE;
	    }

	    /*  CLEAR N PART OF TIME REGISTER  */
	    timeRegister &= (~N_MASK);
	}
    }
    /*  DOWNSAMPLING CONVERSION LOOP  */
    else {
	while (emptyPtr < endPtr) {
	    int index;
	    unsigned int phaseIndex, impulseIndex;
	    double absoluteSampleValue, output, impulse;

	    /*  RESET ACCUMULATOR TO ZERO  */
	    output = 0.0;

	    /*  COMPUTE P PRIME  */
	    phaseIndex = (unsigned int)rint(
		   ((double)fractionValue(timeRegister)) * sampleRateRatio);

	    /*  COMPUTE THE LEFT SIDE OF THE FILTER CONVOLUTION  */
	    index = emptyPtr;
	    while ((impulseIndex = (phaseIndex>>M_BITS)) < FILTER_LENGTH) {
		impulse = h[impulseIndex] + (deltaH[impulseIndex] *
		    (((double)mValue(phaseIndex)) / (double)M_RANGE));
		output += (buffer[index] * impulse);
		srDecrement(&index,BUFFER_SIZE);
		phaseIndex += phaseIncrement;
	    }

	    /*  COMPUTE P PRIME, ADJUSTED FOR RIGHT SIDE  */
	    phaseIndex = (unsigned int)rint(
		((double)fractionValue(~timeRegister)) * sampleRateRatio);

	    /*  COMPUTE THE RIGHT SIDE OF THE FILTER CONVOLUTION  */
	    index = emptyPtr;
	    srIncrement(&index,BUFFER_SIZE);
	    while ((impulseIndex = (phaseIndex>>M_BITS)) < FILTER_LENGTH) {
		impulse = h[impulseIndex] + (deltaH[impulseIndex] *
		    (((double)mValue(phaseIndex)) / (double)M_RANGE));
		output += (buffer[index] * impulse);
		srIncrement(&index,BUFFER_SIZE);
		phaseIndex += phaseIncrement;
	    }

	    /*  RECORD MAXIMUM SAMPLE VALUE  */
	    absoluteSampleValue = fabs(output);
	    if (absoluteSampleValue > maximumSampleValue)
		maximumSampleValue = absoluteSampleValue;

	    /*  INCREMENT SAMPLE NUMBER  */
	    numberSamples++;

#ifdef GNUSTEP
	    float outputFloat = output;
	    struct timespec pause = { 0, MIN_LATENCY_NS };
	    while (jack_ringbuffer_write_space(jackData.ringBuffer) < sizeof(float)) {
                if (getTubeThreadFlag() == TUBE_THREAD_FLAG_EXIT) {
                    return;
                }
	        nanosleep(&pause, NULL);
	    }
	    size_t bytesWritten = jack_ringbuffer_write(jackData.ringBuffer, (const char*) &outputFloat, sizeof(float));
	    assert(bytesWritten == sizeof(float));

	    putCircBuff(outputFloat);
#else
		// OUTPUT SAMPLE TO CIRCBUFF2
		pthread_mutex_lock (&circBuff2Mutex);
	outWait2: while (circBuff2Flag == FULL) pthread_cond_wait(&circBuff2Cond, &circBuff2Mutex); // if circBuff2 full, sleep & wait
		if (circBuff2Flag == FULL) goto outWait2;
		int failed = putCircBuff2((float)output); // if room, put output in circBuff2
		if (failed) goto outWait2;

		pthread_cond_signal(&circBuff2Cond);
		pthread_mutex_unlock(&circBuff2Mutex);
#endif
		//printf("tube.c: %f  ", output);


	    /*  INCREMENT THE TIME REGISTER  */
	    timeRegister += timeRegisterIncrement;

	    /*  INCREMENT THE EMPTY POINTER, ADJUSTING IT AND END POINTER  */
	    emptyPtr += nValue(timeRegister);
	    if (emptyPtr >= BUFFER_SIZE) {
		emptyPtr -= BUFFER_SIZE;
		endPtr -= BUFFER_SIZE;
	    }

	    /*  CLEAR N PART OF TIME REGISTER  */
	    timeRegister &= (~N_MASK);
	}
    }
}



/******************************************************************************
*
*	function:	flushBuffer
*
*	purpose:	Pads the buffer with zero samples, and flushes it by
*                       converting the remaining samples.
*
*       arguments:      none
*
*	internal
*	functions:	dataFill, dataEmpty
*
*	library
*	functions:	none
*
******************************************************************************/
#if 0
void flushBuffer(void)
{
    int i;


    /*  PAD END OF RING BUFFER WITH ZEROS  */
    for (i = 0; i < (padSize * 2); i++)
	dataFill(0.0);

    /*  FLUSH UP TO FILL POINTER - PADSIZE  */
    dataEmpty();
}
#endif


/******************************************************************************
*
*	function:	srIncrement
*
*	purpose:	Increments the pointer, keeping it within the range
*                       0 to (modulus-1).
*
*       arguments:      pointer, modulus
*
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

void srIncrement(int *pointer, int modulus)
{
    if ( ++(*pointer) >= modulus)
	(*pointer) -= modulus;
}



/******************************************************************************
*
*	function:	srDecrement
*
*	purpose:	Decrements the pointer, keeping it within the range
*                       0 to (modulus-1).
*
*       arguments:      pointer, modulus
*
*	internal
*	functions:	none
*
*	library
*	functions:	none
*
******************************************************************************/

void srDecrement(int *pointer, int modulus)
{
    if ( --(*pointer) < 0)
	(*pointer) += modulus;
}

/*  FUNCTIONS TO ALLOW OBJECTIVE-C TO SET TUBE PARAMETERS  */

void tube_setGlotPitch(float value)
{
	inputParameters.glotPitch = value;
}

void tube_setGlotVol(float value)
{
	inputParameters.glotVol = value;
}

void tube_setAspVol(float value)
{
	inputParameters.aspVol = value;
}

void tube_setFricVol(float value)
{
	inputParameters.fricVol = value;
}

void tube_setFricPos(float value)
{
	inputParameters.fricPos = value;
}

void tube_setFricCF(float value)
{
	inputParameters.fricCF = value;
}

void tube_setFricBW(float value)
{
	inputParameters.fricBW = value;
}

void tube_setVelumRadius(float value)
{
	inputParameters.velum = value;
}

void tube_setRadius(float value, int index)
{
	inputParameters.radius[index] = value;
}

void tube_setNoseRadius(float value, int index)
{
	inputParameters.noseRadius[index] = value;
}

//void tube_setVolume(float value)
//{
//	volume = value;
//}

void tube_setWaveformType(int value)
{
	waveform = value;
}

void tube_setTp(float value)
{
	tp = value;
}

void tube_setTnMin(float value)
{
	tnMin = value;
}

void tube_setTnMax(float value)
{
	tnMax = value;
}

void tube_setBreathiness(float value)
{
	breathiness = value;
}

void tube_setLength(float value)
{
	length = value;
}

void tube_setTemperature(float value)
{
	temperature = value;
}

void tube_setLossFactor(float value)
{
	lossFactor = value;
}

void tube_setApScale(float value)
{
	apScale = value;
}

void tube_setMouthCoef(float value)
{
	mouthCoef = value;
}

void tube_setNoseCoef(float value)
{
	noseCoef = value;
}

void tube_setThroatCutoff(float value)
{
	throatCutoff = value;
}

void tube_setThroatVol(float value)
{
	throatVol = value;
}

void tube_setModulation(int value)
{
	modulation = value;
}

void tube_setMixOffset(float value)
{
	mixOffset = value;
}

void tube_setActualTubeLength(float value)
{
	actualTubeLength = value;
}

void tube_setControlPeriod(int value)
{
	controlPeriod = value;
}

void tube_setSampleRate(int value)
{
	sampleRate = value;
}

/*  FUNCTIONS TO ALLOW INTERFACE OBJECTIVE-C ACCESS TO DEFAULT TUBE PARAMETERS  */

float tube_getGlotPitchDefault()
{
	return originalDefaults.glotPitch;
}

float tube_getGlotVolDefault()
{
	return originalDefaults.glotVol;
}

float tube_getAspVolDefault()
{
	return originalDefaults.aspVol;
}

float tube_getFricVolDefault()
{
	return originalDefaults.fricVol;
}

float tube_getFricPosDefault()
{
	return originalDefaults.fricPos;
}

float tube_getFricCFDefault()
{
	return originalDefaults.fricCF;
}

float tube_getFricBWDefault()
{
	return originalDefaults.fricBW;
}

float tube_getVelumRadiusDefault()
{
	return originalDefaults.velum;
}

float tube_getRadiusDefault(int index)
{
	return originalDefaults.radius[index];
}

float tube_getNoseRadiusDefault(int index)
{
	return originalDefaults.noseRadius[index];
}

//float tube_getVolumeDefault()
//{
//	return volume;
//}

int tube_getWaveformTypeDefault()
{
	return waveform;
}

//float tube_getBalanceDefault()
//{
//	return balance;
//}

float tube_getTpDefault()
{
	return tp;
}

float tube_getTnMinDefault()
{
	return tnMin;
}

float tube_getTnMaxDefault()
{
	return tnMax;
}

float tube_getBreathinessDefault()
{
	return breathiness;
}

float tube_getLengthDefault()
{
	return length;
}

float tube_getTemperatureDefault()
{
	return temperature;
}

float tube_getLossFactorDefault()
{
	return lossFactor;
}

float tube_getApScaleDefault()
{
	return apScale;
}

float tube_getMouthCoefDefault()
{
	return mouthCoef;
}

float tube_getNoseCoefDefault()
{
	return noseCoef;
}

float tube_getThroatCutoffDefault()
{
	return throatCutoff;
}

float tube_getThroatVolDefault()
{
	return throatVol;
}

int tube_getModulationDefault()
{
	return modulation;
}

float tube_getMixOffsetDefault()
{
	return mixOffset;
}

/*  FUNCTIONS TO ALLOW INTERFACE OBJECTIVE-C ACCESS TO TUBE PARAMETERS  */

float tube_getGlotPitch()
{
	return inputParameters.glotPitch;
}

float tube_getGlotVol()
{
	return inputParameters.glotVol;
}

float tube_getAspVol()
{
	return inputParameters.aspVol;
}

float tube_getFricVol()
{
	return inputParameters.fricVol;
}

float tube_getFricPos()
{
	return inputParameters.fricPos;
}

float tube_getFricCF()
{
	return inputParameters.fricCF;
}

float tube_getFricBW()
{
	return inputParameters.fricBW;
}

float tube_getVelumRadius()
{
	return inputParameters.velum;
}

float tube_getRadius(int index)
{
	return inputParameters.radius[index];
}

float tube_getNoseRadius(int index)
{
	return inputParameters.noseRadius[index];
}

//float tube_getVolume()
//{
//	return volume;
//}

int tube_getWaveformType()
{
	return waveform;
}

//float tube_getBalance()
//{
//	return balance;
//}

float tube_getTp()
{
	return tp;
}

float tube_getTnMin()
{
	return tnMin;
}

float tube_getTnMax()
{
	return tnMax;
}

float tube_getBreathiness()
{
	return breathiness;
}

float tube_getLength()
{
	return length;
}

float tube_getTemperature()
{
	return temperature;
}

float tube_getLossFactor()
{
	return lossFactor;
}

float tube_getApScale()
{
	return apScale;
}

float tube_getMouthCoef()
{
	return mouthCoef;
}

float tube_getNoseCoef()
{
	return noseCoef;
}

float tube_getThroatCutoff()
{
	return throatCutoff;
}

float tube_getThroatVol()
{
	return throatVol;
}

int tube_getModulation()
{
	return modulation;
}

float tube_getMixOffset()
{
	return mixOffset;
}

float tube_getActualTubeLength()
{
	return actualTubeLength;
}

int tube_getSampleRate()
{
	//printf("Sample rate in get routine is %f\n", sampleRate);
	return sampleRate;
}

int tube_getControlPeriod()
{
	//printf("Control period in get routine is %f\n", controlPeriod);
	return controlPeriod;
}

float tube_getControlRate()
{
	return controlRate;
}

float tube_getWavetable(int index)
{
	return wavetable[index];
}

//int * tube_getThreadFlag()
//{
//	return &threadFlag;
//}

void initCircBuff()
{
	circBuffInPtr = &circBuff[0];
	circBuffOutPtr = &circBuff[1];
	//printf("in, out, first and last pointers are: %d %d %d %d \n", circBuffInPtr, circBuffOutPtr, circBuff, circBuffEnd);
	return;
}

void putCircBuff(float circBuffValue)
{
	pthread_mutex_lock(&circBuffMutex);

	*circBuffInPtr = circBuffValue;
	circBuffInPtr = circBuffOutPtr;
	if (circBuffOutPtr == circBuffEnd) {
		circBuffOutPtr = circBuffStart;
	} else {
		++circBuffOutPtr;
	}

	pthread_mutex_unlock(&circBuffMutex);
}

// bufferCopy must point to a buffer of size CIRC_BUFF_SIZE.
void tube_getCircBuff(float *bufferCopy)
{
	pthread_mutex_lock(&circBuffMutex);

	float *out = circBuffOutPtr;
	int i;
	for (i = 0; i < CIRC_BUFF_SIZE; i++) {
		bufferCopy[i] = *out;
		if (out == circBuffEnd) {
			out = circBuffStart;
		} else {
			++out;
		}
	}

	pthread_mutex_unlock(&circBuffMutex);
}

#ifndef GNUSTEP

void initCircBuff2()
{
	circBuff2InPtr = circBuff2OutPtr = &circBuff2[0];
	circBuff2End = &circBuff2 [CIRC_BUFF2_SIZE -1]; //[CIRC_BUFF2_SIZE - sizeof(float)];
	//printf("tube.c: CircBuff2 in, out, first and last pointers are: %d %d %d %d \n", circBuff2InPtr, circBuff2OutPtr, circ2Buff, circBuff2End);
	circBuff2Flag = EMPTY;
	return;
}

int putCircBuff2(float circBuff2Value)
{
	int error = 1;
	if (circBuff2InPtr == circBuff2OutPtr - 1) { //sizeof(float)) {
		circBuff2Flag = FULL;
		return error;
	}

	else {
		//printf("tube.c: entering putCircBuff2, flag is %d, value is %f In is %d\n", circBuff2Flag, circBuff2Value, circBuff2InPtr);
		if (circBuff2InPtr == circBuff2End) //&circBuff2[CIRC_BUFF2_SIZE - sizeof(double)])
			{
			if (circBuff2OutPtr == &circBuff2[0])
				{
				circBuff2Flag = FULL;
				return error;
				}

			*circBuff2InPtr = circBuff2Value;

			circBuff2Count += 1;
			//printf("tube.c: circBuff2Count is %d\n", circBuff2Count);

			//circBuff2InPtr++;
			error = 0;

			//printf("tube.c: circBuff2Value is %f\n", circBuff2Value);

			circBuff2InPtr = &circBuff2[0];

			circBuff2Flag = OK;
			return error;

		}

		*circBuff2InPtr = circBuff2Value;
		circBuff2Flag = OK;
		circBuff2Count += 1;
		//printf("tube.c: circBuff2Count is %d\n", circBuff2Count);

		error = 0;
		//printf("tube.c: value in 'IN' position of circBuff is %f InPtr is %d\n", *circBuff2InPtr, circBuff2InPtr);

		circBuff2InPtr++;
		circBuff2Flag = OK;
		return error;
	}
}

float getCircBuff2()
{
	float circBuff2Value;


	pthread_mutex_lock (&circBuff2Mutex);
waitCB2:	while (circBuff2Flag == EMPTY) pthread_cond_wait (&circBuff2Cond, &circBuff2Mutex); // if circBuff2 EMPTY, sleep & wait

	if (circBuff2InPtr == circBuff2OutPtr) goto waitCB2;
	circBuff2Value = *circBuff2OutPtr;
	circBuff2Count -= 1;
	if (circBuff2OutPtr == circBuff2End) circBuff2OutPtr = &circBuff2[0];
	else circBuff2OutPtr++;
	if (circBuff2InPtr == circBuff2OutPtr) {
		circBuff2Flag = EMPTY;
		//goto waitCB2;
		}
	else circBuff2Flag = OK; // else circBuff2Flag = OK;
	//printf("In getCircBuff2 tube.c: circBuff2OutPtr is %d circBuff2Value is %f\n", circBuff2OutPtr, circBuff2Value);


	pthread_mutex_unlock (&circBuff2Mutex);
	pthread_cond_signal(&circBuff2Cond);

	//pthread_mutex_lock (&circBuffMutex);

	if (circBuffFlag == FULL) getCircBuff(); // If circBuff is FULL, discard earliest sample to make room

	putCircBuff(circBuff2Value);

	//pthread_mutex_unlock (&circBuffMutex);
	//pthread_cond_signal(&circBuffCond);

	return circBuff2Value;

}

#endif /* GNUSTEP */
