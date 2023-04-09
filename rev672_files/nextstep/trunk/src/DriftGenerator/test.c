/*  HEADER FILES  ************************************************************/
#include <stdio.h>
#include "driftGenerator.h"


/******************************************************************************
*
*	function:	main
*
*	purpose:	Tests the drift generator routines.
*                       
*       arguments:      none
*                       
*	internal
*	functions:	setDriftGenerator, drift
*
*	library
*	functions:	printf, scanf
*
******************************************************************************/

void main (int argc, char *argv[])
{
    float pitchDeviation, sampleRate, lowpassCutoff;
    int i, iterations;
    

    while(1) {
	/*  QUERY FOR PITCH DEVIATION  */
	printf("\nPitch deviation (0.0 - 10.0 semitones):  ");
	scanf("%f", &pitchDeviation);

	/*  QUERY FOR SAMPLE RATE  */
	printf("Sample Rate (100.0 - 1000.0 Hz):  ");
	scanf("%f", &sampleRate);

	/*  QUERY FOR LOWPASS CUTOFF FREQUENCY  */
	printf("Lowpass Cutoff (0.0 - %.1f Hz):  ", sampleRate/2.0);
	scanf("%f", &lowpassCutoff);

	/*  QUERY FOR NUMBER OF SAMPLES TO PRODUCE  */
	printf("Iterations (1 - 1000):  ");
	scanf("%d", &iterations);

	/*  SET THE DRIFT GENERATOR TO THESE PARAMETERS  */
	setDriftGenerator(pitchDeviation, sampleRate, lowpassCutoff);

	/*  PRINT OUT THE DRIFT SIGNAL  */
	printf("\n");
	for (i = 0; i < iterations; i++)
	    printf("%+1.2f\n", drift());
    }
}
