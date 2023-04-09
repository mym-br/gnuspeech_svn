/*  REVISION INFORMATION  *****************************************************

$Author: len $
$Date: 1994/06/16 16:40:12 $
$Revision: 1.1.1.1 $
$Source: /cvsroot/ToneGenerator/Tone.m,v $
$State: Exp $


$Log: Tone.m,v $
# Revision 1.1.1.1  1994/06/16  16:40:12  len
# Initial archive of ToneGenerator application.
#

******************************************************************************/


/*  HEADER FILES  ************************************************************/
#import "Tone.h"
#import "conversion.h"
#import "dsp_control.h"



@implementation Tone

- init
{
    /*  DO SUPERCLASS INITIALIZATION  */
    self = [super init];

    /*  SET THE THE INSTANCE VARIABLES TO DEFAULT VALUES  */
    isPlaying = NO;
    frequency = FREQUENCY_DEF;
    amplitude = amplitudeOf(VOLUME_DEF);
    balance = BALANCE_DEF;
    numberHarmonics = HARMONICS_DEF;
    rampTime = RAMP_TIME_DEF;

    /*  INITIALIZE THE SYNTHESIZER  */
    initialize_synthesizer();

    return self;
}



- free
{
    /*  MAKE SURE WE HAVE STOPPED PLAYING BEFORE FREEING  */
    if (isPlaying)
	[self stopTone];

    /*  FREE MEMORY ASSOCIATED WITH THE SYNTHESIZER  */
    free_synthesizer();

    /*  DO SUPERCLASS FREE & RETURN  */
    return [super free];
}



- playTone
{
    /*  RETURN IMMEDIATELY, IF WE ARE ALREADY PLAYING  */
    if (isPlaying)
	return self;

    /*  TRY TO GRAB & INITIALIZE THE DSP, RETURNING NIL IF WE CANNOT  */
    if (grab_and_initialize_DSP() == ST_ERROR)
	return nil;

    /*  TURN ON PLAYING FLAG  */
    isPlaying = YES;

    /*  SET THE WAVETABLE  */
    set_wavetable(numberHarmonics);

    /*  SET THE FREQUENCY OF THE TONE  */
    set_frequency(frequency);

    /*  SET THE AMPLITUDE OF THE TONE  */
    set_amplitude(amplitude);

    /*  SET THE BALANCE OF THE TONE  */
    set_balance(balance);

    /*  SET THE RAMP TIME  */
    set_ramptime(rampTime);

    /*  START THE TONE GENERATOR  */
    start_synthesizer();

    return self;
}



- stopTone
{
    /*  RETURN IMMEDIATELY, IF WE ARE ALREADY STOPPED  */
    if (!isPlaying)
	return self;

    /*  STOP THE TONE GENERATOR;  THIS BLOCKS FOR AS LONG AS THE RAMPTIME  */
    stop_synthesizer();

    /*  RELINQUISH THE DSP  */
    relinquish_DSP();

    /*  TURN OFF PLAYING FLAG  */
    isPlaying = NO;

    return self;
}



- setFrequency:(float)value
{
    /*  MAKE SURE FREQUENCY IS IN RANGE  */
    if (value < FREQUENCY_MIN)
	value = FREQUENCY_MIN;
    else if (value > FREQUENCY_MAX)
	value = FREQUENCY_MAX;

    /*  SET THE FREQUENCY INSTANCE VARIABLE  */
    frequency = value;

    /*  SET THE VALUE IN THE DSP, IF IT IS RUNNING  */
    if (isPlaying)
	set_frequency(frequency);

    return self;
}



- setPitch:(float)value
{
    /*  CONVERT PITCH TO FREQUENCY, AND THEN SET FREQUENCY  */
    return [self setFrequency:frequencyOf(value)];
}



- setAmplitude:(float)value
{
    /*  MAKE SURE AMPLITUDE IS IN RANGE  */
    if (value < AMPLITUDE_MIN)
	value = AMPLITUDE_MIN;
    else if (value > AMPLITUDE_MAX)
	value = AMPLITUDE_MAX;

    /*  SET THE AMPLITUDE INSTANCE VARIABLE  */
    amplitude = value;

    /*  SET THE VALUE IN THE DSP, IF IT IS RUNNING  */
    if (isPlaying)
	set_amplitude(amplitude);

    return self;
}



- setVolume:(float)value
{
    /*  CONVERT DB VALUE TO AMPLITUDE, AND THEN SET AMPLITUDE  */
    return [self setAmplitude:amplitudeOf(value)];
}



- setStereoBalance:(float)value
{
    /*  MAKE SURE BALANCE IS IN RANGE  */
    if (value < BALANCE_MIN)
	value = BALANCE_MIN;
    else if (value > BALANCE_MAX)
	value = BALANCE_MAX;

    /*  SET THE BALANCE INSTANCE VARIABLE  */
    balance = value;

    /*  SET THE VALUE IN THE DSP, IF IT IS RUNNING  */
    if (isPlaying)
	set_balance(balance);

    return self;
}



- setNumberHarmonics:(int)value
{
    /*  MAKE SURE NUMBER HARMONICS IS IN RANGE  */
    if (value < HARMONICS_MIN)
	value = HARMONICS_MIN;
    else if (value > HARMONICS_MAX)
	value = HARMONICS_MAX;

    /*  SET THE NUMBER HARMONICS INSTANCE VARIABLE  */
    numberHarmonics = value;

    /*  SET THE VALUE IN THE DSP, IF IT IS RUNNING  */
    if (isPlaying)
	set_wavetable(numberHarmonics);

    return self;
}



- setRampTime:(float)value
{
    /*  MAKE SURE VALUE IS IN RANGE  */
    if (value < RAMP_TIME_MIN)
	value = RAMP_TIME_MIN;
    else if (value > RAMP_TIME_MAX)
	value = RAMP_TIME_MAX;

    /*  SET THE RAMP TIME INSTANCE VARIABLE  */
    rampTime = value;

    /*  SET THE VALUE IN THE DSP, IF IT IS RUNNING  */
    if (isPlaying)
	set_ramptime(rampTime);

    return self;
}



- (float)frequency
{
    /*  RETURN THE CURRENT FREQUENCY  */
    return frequency;
}



- (float)pitch
{
    /*  RETURN THE CURRENT PITCH  */
    return pitchOf(frequency);
}



- (float)amplitude
{
    /*  RETURN THE CURRENT AMPLITUDE  */
    return amplitude;
}



- (float)volume
{
    /*  RETURN THE CURRENT VOLUME  */
    return volumeOf(amplitude);
}



- (float)stereoBalance
{
    /*  RETURN THE CURRENT BALANCE  */
    return balance;
}



- (int)numberHarmonics
{
    /*  RETURN THE CURRENT NUMBER OF HARMONICS  */
    return numberHarmonics;
}



- (float)rampTime
{
    /*  RETURN THE CURRENT RAMP TIME  */
    return rampTime;
}



- (BOOL)isPlaying
{
    /*  RETURN THE PLAYING STATUS  */
    return isPlaying;
}

@end
