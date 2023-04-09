/*
 *    Filename:	MKTone.m 
 *    Created :	Fri Jun 18 20:11:53 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Mon Jul 11 00:47:47 1994"
 *
 * $Id: MKTone.m,v 1.1 1994/07/25 06:24:20 dale Exp $
 *
 * $Log: MKTone.m,v $
 * Revision 1.1  1994/07/25  06:24:20  dale
 * Initial revision
 *
 * Revision 1.1  1994/07/25  05:59:29  dale
 * Initial revision
 *
 * Revision 1.1  1994/07/25  02:30:52  dale
 * Initial revision
 *
 * Revision 1.5  1994/06/15  19:32:35  dale
 * Added comments and debugging variables suggested by David Jaffe.
 *
 * Revision 1.4  1994/06/10  20:18:28  dale
 * *** empty log message ***
 *
 * Revision 1.3  1994/06/03  08:03:28  dale
 * *** empty log message ***
 *
 * Revision 1.2  1993/06/22  19:50:38  dale
 * Adjusted default waveform to english horn.
 *
 * Revision 1.1  1993/06/19  08:24:38  dale
 * Initial revision
 *
 */

#import <musickit/musickit.h>
#import <musickit/synthpatches/synthpatches.h>
#import <appkit/nextstd.h>
#import "MKTone.h"

/* Courtesy of david@jaffe.com (David A. Jaffe). These are some undocumented debugging variables that
 * can be used to provide additional information when debugging the MusicKit and DSP. These variables
 * should be set to -1 before the DSP is opened.
 */
#ifdef MK_TONE_DEBUG
    extern int _DSPTrace;
    extern int _DSPVerbose;
#endif /* MK_TONE_DEBUG */


@implementation MKTone


/* INITIALIZING AND FREEING *************************************************************************/


/* Initialization, and default settings. Note, if parameters are not set in the updateNote, then they
 * "inherit" those parameters that were set in the "onNote". Returns self. 
 */
- init
{
    [super init];
    synthPatchClass = [DBWave1vi class];
    frequency = 0.0;   // init to 0.0 frequency (no sound)
    amplitude = 0.1;
    isPlaying = NO;

#ifdef MK_TONE_DEBUG
    DSPEnableErrorFile("/dev/tty");
    DSPEnableErrorLog();
    MKSetTrace(MK_TRACEORCHALLOC);   // trace musickit orchestra allocation
    _DSPTrace = -1;   // set DSP trace
    _DSPVerbose = -1;   // set verbose DSP trace
#endif /* MK_TONE_DEBUG */

    // create and set parameters for "on" note
    onNote = [[Note allocFromZone:[self zone]] init];
    [onNote setNoteType:MK_noteOn];
    [onNote setNoteTag:MKNoteTag()];
    [onNote setPar:MK_waveform toString:"OB"];    // oboe is default
    [onNote setPar:MK_amp toDouble:amplitude];    // amplitute (loudness)
    [onNote setPar:MK_freq toDouble:frequency];   // frequency (pitch)

    // create and set parameters for "off" note
    offNote = [[Note allocFromZone:[self zone]] init];
    [offNote setNoteType:MK_noteOff];
    [offNote setNoteTag:[onNote noteTag]];

    // create and set parameters for "update" note
    updateNote = [[Note allocFromZone:[self zone]] init];
    [updateNote setNoteType:MK_noteUpdate];
    [updateNote setNoteTag:[onNote noteTag]];

    // initialize the Orchestra
    orchestra = [Orchestra new];
    [orchestra setFastResponse:YES];
    [orchestra setTimed:NO];    
    [orchestra setSamplingRate:44100.0];

    // create and initialize an instance of SynthInstrument (what "realizes" the notes)
    instrument = [[SynthInstrument allocFromZone:[self zone]] init];
    [instrument setSynthPatchClass:[synthPatchClass class]];

    return self;
}

- free
{
    [onNote free];
    [updateNote free];
    [offNote free];
    [instrument free];
    if (![orchestra close]) {
	NXLogError("Unable to close Orchestra instance.");
    }
    if (![orchestra free]) {
	NXLogError("Unable to free Orchestra instance.");
    }
    return [super free];
}


/* PLAYING AND STOPPING *****************************************************************************/


/* Plays the note. If we are unable to open the DSP we return nil, otherwise we return self. Note that
 * we do not need to send the -startPerformance message to the Conductor since we never use it. It 
 * would be used when note timings were important. Here we don't use note timings (hence the 
 * Conductor) since we send notes manually to the SynthInstrument. Returns self.
 */
- playTone
{
    if (![orchestra run])   // unable to open and start the clock on the DSP
	return nil;

    // send the "on" note directly to the instrument
    [[instrument noteReceiver] receiveNote:onNote];
    isPlaying = YES;
    return self;
}

/* Stop playing the note, and break the connection to the DSP by closing the instance of Orchestra. If
 * any errors occur, print an error message to the console and return nil, otherwise return self.
 */
- stopTone
{
    // send the "off" note directly to the instrument
    [[instrument noteReceiver] receiveNote:offNote];
    isPlaying = NO;
    if (![orchestra close]) {   // attempt to close the connection to the DSP
	NXLogError("Unable to close Orchestra instance.");
	return nil;
    }
    return self;
}


/* SET METHODS **************************************************************************************/


/* Frequency is measured in hertz. If no note is currently being played, we just set the frequency of
 * the onNote. If a note IS currently being played, then we update the existing note to the required 
 * frequency via the updateNote. Returns self.
 */
- setFrequency:(float)freq
{
    frequency = freq;
    if (isPlaying) {   // send updateNote after adjusting frequency
	[updateNote setPar:MK_freq toDouble:freq];
	[[instrument noteReceiver] receiveNote:updateNote];
    } else {   // not yet playing, just adjust onNote frequency
	[onNote setPar:MK_freq toDouble:freq];
    }
    return self;
}

- setSynthPatchClass:(Class)synthPatch
{
    synthPatchClass = synthPatch;
    [instrument setSynthPatchClass:synthPatch];
    return self;
}

/* The waveform should be a character string described in MusicKit+DSP/Music/Reference/MusicKit.rtf in
 * the section titled "WaveTable Database". If no note is currently being played, we just set the 
 * waveform of the onNote. If a note IS currently being played, then we update the existing note to 
 * the required waveform via the updateNote. Returns self.
 */    
- setWaveform:(const char *)name
{
    if (isPlaying) {   // send updateNote after adjusting waveform name
	[updateNote setPar:MK_waveform toString:(char *)name];
	[[instrument noteReceiver] receiveNote:updateNote];
    } else {   // not yet playing, just adjust onNote waveform name
	[onNote setPar:MK_waveform toString:(char *)name];
    }
    return self;
}

/* Amplitude should be between 0.0 and 1.0, where 0.0 is inaudibly soft, and 1.0 is a fully saturated
 * signal. Returns self.
 */
- setAmplitude:(float)amp
{
    amplitude = amp;
    if (isPlaying) {   // send updateNote after adjusting frequency
	[updateNote setPar:MK_amp toDouble:amp];
	[[instrument noteReceiver] receiveNote:updateNote];
    } else {   // not yet playing, just adjust onNote frequency
	[onNote setPar:MK_amp toDouble:amp];
    }
    return self;
}


/* QUERY METHODS ************************************************************************************/


- (float)frequency
{
    return frequency;
}

- (Class)synthPatchClass
{
    return synthPatchClass;
}

- (float)amplitude
{
    return amplitude;
}

- (BOOL)isPlaying
{
    return isPlaying;
}

@end
