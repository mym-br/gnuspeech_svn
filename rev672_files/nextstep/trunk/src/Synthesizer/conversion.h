/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:54 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/Synthesizer/conversion.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
 * Revision 1.1.1.1  1994/05/20  00:22:02  len
 * Initial archive of TRM interactive Synthesizer.
 *

******************************************************************************/

/*  GLOBAL FUNCTIONS *********************************************************/
extern double frequency(double pitch);
extern double Pitch(double frequency);
extern float normalizedPitch(int semitones, int cents);
extern float scaledVolume(float decibel_level);
extern double amplitude(double decibelLevel);

/*  GLOBAL DEFINES  **********************************************************/
#define VOLUME_MIN        0
#define VOLUME_MAX        60
#define VOLUME_DEF        60

#define PITCH_BASE        220.0
#define PITCH_OFFSET      3           /*  MIDDLE C = 0  */
#define LOG_FACTOR        3.32193

#define AMPLITUDE_SCALE       64.0        /*  DIVISOR FOR AMPLITUDE SCALING  */
#define CROSSMIX_FACTOR_SCALE 32.0  /*  DIVISOR FOR CROSSMIX_FACTOR SCALING  */
#define POSITION_SCALE        8.0    /*  DIVISOR FOR FRIC. POSITION SCALING  */

