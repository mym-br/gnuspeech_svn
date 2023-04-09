/*  REVISION INFORMATION  *****************************************************

$Author: rao $
$Date: 2002-03-21 16:49:54 $
$Revision: 1.1 $
$Source: /Users/dalmazio/cvsroot/gnuspeech/trillium/src/ToneGenerator/Tone.h,v $
$State: Exp $


$Log: not supported by cvs2svn $
 * Revision 1.1.1.1  1994/06/16  16:40:12  len
 * Initial archive of ToneGenerator application.
 *

******************************************************************************/


/*  HEADER FILES  ************************************************************/
#import "dsp_control.h"
#import <objc/Object.h>


/*  GLOBAL DEFINES  **********************************************************/
#define FREQUENCY_MIN    0.0
#define FREQUENCY_MAX    (OUTPUT_SRATE/4.0)
#define FREQUENCY_DEF    FREQUENCY_MIN

#define PITCH_MIN        (-36.0)
#define PITCH_MAX        36.0
#define PITCH_DEF        0.0

#define AMPLITUDE_MIN    0.0
#define AMPLITUDE_MAX    1.0
#define AMPLITUDE_DEF    0.1

#define VOLUME_MIN       0.0
#define VOLUME_MAX       60.0
#define VOLUME_DEF       54.0

#define BALANCE_L        (-1.0)
#define BALANCE_R        1.0
#define BALANCE_C        0.0
#define BALANCE_MIN      BALANCE_L
#define BALANCE_MAX      BALANCE_R
#define BALANCE_DEF      BALANCE_C

#define HARMONICS_MIN    1
#define HARMONICS_MAX    (WAVETABLE_SIZE/8)
#define HARMONICS_DEF    HARMONICS_MIN

#define RAMP_TIME_MIN    0.0
#define RAMP_TIME_MAX    5.0
#define RAMP_TIME_DEF    0.25



@interface Tone:Object
{
    float frequency;
    float amplitude;
    float balance;
    int numberHarmonics;
    float rampTime;
    BOOL isPlaying;
}

/*  INITIALIZING AND FREEING  */
- init;
- free;

/*  PLAYING AND STOPPING  */
- playTone;
- stopTone;

/*  SET METHODS  */
- setFrequency:(float)value;
- setPitch:(float)value;
- setAmplitude:(float)value;
- setVolume:(float)value;
- setStereoBalance:(float)value;
- setNumberHarmonics:(int)value;
- setRampTime:(float)value;

/*  QUERY METHODS  */
- (float)frequency;
- (float)pitch;
- (float)amplitude;
- (float)volume;
- (float)stereoBalance;
- (int)numberHarmonics;
- (float)rampTime;
- (BOOL)isPlaying;

@end
