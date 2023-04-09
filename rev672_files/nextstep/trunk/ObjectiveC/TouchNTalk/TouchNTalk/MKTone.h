/*
 *    Filename:	MKTone.h 
 *    Created :	Fri Jun 18 20:11:36 1993 
 *    Author  :	Dale Brisinda
 *		<dale@pegasus.cuc.ab.ca>
 *
 *    Last modified on "Mon Jul 11 00:40:39 1994"
 *
 * $Id: MKTone.h,v 1.1 1994/07/25 06:24:20 dale Exp $
 *
 * $Log: MKTone.h,v $
 * Revision 1.1  1994/07/25  06:24:20  dale
 * Initial revision
 *
 * Revision 1.1  1994/07/25  05:59:29  dale
 * Initial revision
 *
 * Revision 1.1  1994/07/25  02:30:52  dale
 * Initial revision
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

#import <objc/Object.h>

@interface MKTone:Object
{
    Class synthPatchClass;   // the synthPatch class to use in emitting the tone
    float frequency;         // frequency at which tone should be played
    float amplitude;         // amplitude of tone (loudness)
    BOOL isPlaying;          // is a tone currently being played?
    id orchestra;
    id instrument;
    id onNote;
    id offNote;
    id updateNote;
}

/* INITIALIZING AND FREEING */
- init;
- free;

/* PLAYING AND STOPPING */
- playTone;
- stopTone;

/* SET METHODS */
- setFrequency:(float)freq;
- setSynthPatchClass:(Class)synthPatchClass;
- setWaveform:(const char *)name;
- setAmplitude:(float)amp;

/* QUERY METHODS */
- (float)frequency;
- (Class)synthPatchClass;
- (float)amplitude;
- (BOOL)isPlaying;

@end
