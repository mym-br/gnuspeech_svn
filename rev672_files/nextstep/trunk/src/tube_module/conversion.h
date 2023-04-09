/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:54 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/tube_module/conversion.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
 * Revision 1.3  1995/03/02  02:55:27  len
 * Added means to call user-supplied page_consumed function, added means to
 * set the pad page to user-specified silence, and changed the controlRate
 * variable to a float.
 *
 * Revision 1.2  1994/11/18  04:28:38  len
 * Added high/low (22050/44100 Hz.) output sample rate switch.
 *
 * Revision 1.1.1.1  1994/09/06  21:45:52  len
 * Initial archive into CVS.
 *

******************************************************************************/



/*  GLOBAL FUNCTIONS *********************************************************/
extern void optimizeConversion(float srate, int waveform, float apScale,
			       float n1);

extern void convertLength(float length, float temperature, float controlRate,
			  int *period, float *srate);
extern void convertToTimeRegister(float srate, float outputSampleRate,
				  int *integerPart, int *fractionalPart);

extern float scatteringCoefficient(float radius1, float radius2);
extern float endCoefficient(float radius);
extern float n0Coefficient(float radius);
extern void alphaCoefficients(float pharynx, float oral, float velum,
			      float *alpha0, float *alpha1, float *alpha2);

extern float scaledVolume(float decibelLevel);
extern float amplitude(float decibelLevel);

extern float tableIncrement(float pitch);
extern float frequency(float pitch);
extern float pitch(float frequency);
extern float scaledFrequency(float frequency);

extern float scaledPosition(float position);
extern float scaledCrossmixFactor(float mixOffset);
extern float dampingFactor(float lossFactor);

extern float speedOfSound(float temperature);
