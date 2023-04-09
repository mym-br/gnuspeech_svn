/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:54 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/ToneGenerator/conversion.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
 * Revision 1.1.1.1  1994/06/16  16:40:12  len
 * Initial archive of ToneGenerator application.
 *

******************************************************************************/


/*  GLOBAL FUNCTIONS *********************************************************/
extern float frequencyOf(float pitch);
extern float pitchOf(float frequency);
extern float amplitudeOf(float decibelLevel);
extern float volumeOf(float amplitude);
extern float rate(float rampTime, int sampleRate, float dbDecay);
