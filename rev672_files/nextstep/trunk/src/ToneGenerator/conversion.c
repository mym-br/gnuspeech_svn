/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:54 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/ToneGenerator/conversion.c,v $
$State: Exp $


$Log: not supported by cvs2svn $
 * Revision 1.1.1.1  1994/06/16  16:40:12  len
 * Initial archive of ToneGenerator application.
 *

******************************************************************************/


/*  HEADER FILES  ************************************************************/
#import "conversion.h"
#import <math.h>


/*  LOCAL DEFINES  ***********************************************************/
#define VOLUME_MIN        0.0
#define VOLUME_MAX        60.0
#define VOLUME_DEF        60.0

#define PITCH_BASE        220.0
#define PITCH_OFFSET      3           /*  MIDDLE C = 0  */
#define LOG_FACTOR        3.32193



/******************************************************************************
*
*       function:       frequencyOf
*
*       purpose:        Converts a given pitch (0 = middle C) to the
*                       corresponding frequency.
*
*       arguments:      pitch - input pitch, where 0 = middle C, and the
*                               units are semitones.  Cents are the first two
*                               digits of the fractional part.
*       internal
*       functions:      none
*
*       library
*       functions:      pow
*
******************************************************************************/

float frequencyOf(float pitch)
{
    return(PITCH_BASE * pow(2.0,(((double)(pitch+PITCH_OFFSET))/12.0)));
}



/******************************************************************************
*
*       function:       pitchOf
*
*       purpose:        Converts a given frequency to (fractional) semitone;
*                       0 = middle C.
*
*       arguments:      frequency - frequency to be converted, in Hertz.
*                       
*       internal
*       functions:      none
*
*       library
*       functions:      log10, pow
*
******************************************************************************/

float pitchOf(float frequency)
{
    return(12.0 *
           log10(frequency/(PITCH_BASE * pow(2.0,(PITCH_OFFSET/12.0)))) *
           LOG_FACTOR);
}



/******************************************************************************
*
*       function:       amplitudeOf
*
*       purpose:        Converts dB value to amplitude value.
*
*       arguments:      decibelLevel - input decibel value (0 - 60 dB), to be
*                                      converted to amplitude (0.0 - 1.0).
*       internal
*       functions:      none
*
*       library
*       functions:      pow
*
******************************************************************************/

float amplitudeOf(float decibelLevel)
{
    /*  CONVERT 0-60 RANGE TO -60-0 RANGE  */
    decibelLevel -= VOLUME_MAX;

    /*  IF -60 OR LESS, RETURN AMPLITUDE OF 0  */
    if (decibelLevel <= (-VOLUME_MAX))
        return(0.0);

    /*  IF 0 OR GREATER, RETURN AMPLITUDE OF 1  */
    if (decibelLevel >= 0.0)
        return(1.0);

    /*  ELSE RETURN INVERSE LOG VALUE  */
    return(pow(10.0,(decibelLevel/20.0)));
}



/******************************************************************************
*
*	function:	volumeOf
*
*	purpose:	Converts the amplitude (0.0 - 1.0) to the corresponding
*                       decibel value (0 - 60 dB).
*			
*       arguments:      amplitude - amplitude (0.0 - 1.0) to be converted.
*                       
*	internal
*	functions:	none
*
*	library
*	functions:	log10
*
******************************************************************************/

float volumeOf(float amplitude)
{
    if (amplitude <= 0.0)
	return(VOLUME_MIN);
    else if (amplitude >= 1.0)
	return(VOLUME_MAX);
    else {
	return(VOLUME_MAX + (20.0 * log10(amplitude)));
    }
}



/******************************************************************************
*
*	function:	rate
*
*	purpose:	Converts the rampTime into the "rate" value used by
*                       the asymptotic envelope generator on the DSP.
*			
*       arguments:      rampTime - the time in seconds to ramp to near the
*                                  asymptote.
*                       sampleRate - the sample rate used by the envelope
*                                    generator.
*                       dbDecay - the asymptotic decay curve.  Eg. if dbDecay
*                                 is set to 60 dB, then the envelope generator
*                                 will take "rampTime" seconds to move 60 dB
*                                 from the current amplitude to the target
*                                 amplitude.
*	internal
*	functions:	none
*
*	library
*	functions:	pow
*
******************************************************************************/

float rate(float rampTime, int sampleRate, float dbDecay)
{
    /*  RETURN IMMEDIATELY IF RAMP TIME TOO SMALL  */
    if (rampTime <= 0)
	return(1.0);
    
    /*  RETURN CALCULATED RATE VALUE  */
    return(1.0 - pow(pow(10.0, -dbDecay/20.0), 1.0/(sampleRate * rampTime)));
}
